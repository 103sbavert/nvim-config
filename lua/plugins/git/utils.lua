local M = {}

--- @module "gitsigns?"
local gitsigns = nil

--- @module "gitsigns.cache?"
local gitsigns_cache = nil

--- @module "gitsigns.async?"
local gitsigns_async = nil

local UT = require("config.utils")

--- Cached layout config for Snacks.picker.git* using default options but with
--- a wider preview and fullscreen window. Used for git pickers for a better
--- look at the diff
--- @type snacks.picker.layout.Config
local git_layout = nil

--- @return snacks.picker.layout.Config
function M.get_layout()
    if git_layout then
        return git_layout
    end

    git_layout = vim.deepcopy(require("snacks.picker.config.layouts").default)

    git_layout.fullscreen = true
    git_layout.layout.border = true

    for _, prop in ipairs(git_layout.layout) do
        if prop and type(prop) == "table" then
            if prop.box == "vertical" then
                prop.border = false

                for _, child in ipairs(prop) do
                    if child and type(child) == "table" then
                        if child.win == "input" then
                            child.border = "bottom"
                        elseif child.win == "list" then
                            child.border = false
                        end
                    end
                end
            elseif prop.win == "preview" then
                prop.width = 0.70
                prop.border = "left"
            end
        end
    end

    return git_layout
end

--- Prompts to save buffer if modified. Returns false on cancel.
--- @param bufnr integer
--- @return boolean proceed
function M.ask_save_stage(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end
    if not vim.bo[bufnr].modified then
        return true
    end

    local choice = vim.fn.confirm(
        "Some changes are unsaved. Save changes to disk before staging?\n",
        "&Yes\n&No\n&Cancel",
        1,
        "Warning"
    )

    -- write on yes
    if choice == 1 then
        local ok, err = pcall(
            vim.api.nvim_buf_call,
            bufnr,
            function() vim.cmd.update() end
        )
        if not ok then
            vim.notify(
                "Save failed: " .. tostring(err),
                vim.log.levels.ERROR,
                { title = "Git" }
            )
            return false
        end
        return true
    end

    return choice == 2 -- proceed without saving only on No; Cancel/Esc aborts
end

--- Runs a reset action, offering to save the result afterwards.
--- Skips prompt when buffer unmodified. Cancel runs nothing, writes nothing.
--- @param bufnr integer
--- @param action fun(done: fun()) Reset action, must invoke `done` on completion.
--- @return nil
function M.ask_reset_save(bufnr, action)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    if not vim.bo[bufnr].modified then
        action(function() end)
        return
    end

    local choice = vim.fn.confirm(
        "Some changes are unsaved. Save to disk after reset?\n",
        "&Yes\n&No\n&Cancel",
        3,
        "Warning"
    )

    if choice == 0 or choice == 3 then
        return
    end

    action(function()
        if choice == 1 then
            local ok, err = pcall(
                vim.api.nvim_buf_call,
                bufnr,
                function() vim.cmd.update() end
            )
            if not ok then
                vim.notify(
                    "Save failed: " .. tostring(err),
                    vim.log.levels.ERROR,
                    { title = "Git" }
                )
            end
        end
    end)
end

--- Runs the Neogit commit command in an interactive editor via `client.wrap`.
--- Must be called from within a `neogit.lib.async` context.
--- @return nil
local function commit_popup_cb()
    local commit = require("neogit.lib.git").cli.commit

    require("neogit.client").wrap(commit, {
        msg = {
            success = "Committed",
            fail = "Commit failed",
            title = "Git",
        },
        interactive = true,
        show_diff = true,
    })
end

--- Opens the Neogit commit editor, refreshing repo state first.
--- @return nil
function M.open_commit_tab()
    local git = require("neogit.lib.git")
    local a = require("neogit.lib.async")

    a.void(function()
        a.wrap(
            function(cb)
                git.repo:dispatch_refresh({
                    source = "commit-keymap",
                    callback = cb,
                })
            end,
            1
        )()

        commit_popup_cb()
    end)()
end

local snacks_fmt = nil

--- Formats a git log picker item, prefixing it with a "@" marker column when
--- the item's commit is the current HEAD.
--- @param head_hash string Full SHA of the current HEAD commit.
--- @param item snacks.picker.Item Git log picker item being formatted.
--- @param picker snacks.Picker Picker instance the item belongs to.
--- @return snacks.picker.Highlight[] Formatted item parts with head highlighting.
local function format_log(head_hash, commit_icon, item, picker)
    if not snacks_fmt then
        snacks_fmt = {
            align = Snacks.picker.util.align,
            extend = Snacks.picker.highlight.extend,
            commit_message = Snacks.picker.format.commit_message,
        }
    end

    local align = snacks_fmt.align

    local is_head = vim.startswith(head_hash, item.commit)
    local symbol
    local hl

    if is_head then
        symbol = " "
        hl = "SnacksPickerGitBranchCurrent"
    else
        symbol = commit_icon
        hl = "SnacksPickerGitCommit"
    end

    local shorthash = align(item.commit, 7, { truncate = true })

    local fmt = {} ---@type snacks.picker.Highlight[]
    fmt[#fmt + 1] = { symbol, hl }
    fmt[#fmt + 1] = { shorthash, hl }

    fmt[#fmt + 1] = { align("", 4) }

    snacks_fmt.extend(fmt, snacks_fmt.commit_message(item, picker))

    return fmt
end

--- Confirm handler for the diff-base commit picker. Closes the picker and
--- forwards the selected commit hash to `callback`; notifies and aborts if
--- no commit was selected.
--- @param picker snacks.Picker Picker instance to close.
--- @param item snacks.picker.Item? Selected picker item.
--- @param callback fun(hash: string) Invoked with the selected commit hash.
--- @return nil
local function on_ref_confirm(picker, item, callback)
    picker:close()

    if not item or not item.commit or item.commit == "" then
        vim.notify(
            "No commit selected",
            vim.log.levels.WARN,
            { title = "Diff" }
        )
        return
    end

    callback(item.commit)
end

--- Opens the git log picker with a pre-resolved HEAD hash.
--- @param head_hash string Full HEAD oid used for the current-commit marker.
--- @param file_name? string optional file name to query log against
--- @param callback? fun(hash: string) Invoked with the chosen commit hash, use
--- nil to use Snacks.picker.git_log default on_confirm action
--- @return nil
local function open_log_picker(head_hash, file_name, callback)
    --- @type snacks.picker.git.log.Config
    local git_log_opts = {
        -- Resolves the commit icon once per picker instead of per item.
        format = (function()
            local commit_icon = nil
            return function(item, picker)
                commit_icon = commit_icon or picker.opts.icons.git.commit
                return format_log(head_hash, commit_icon, item, picker)
            end
        end)(),
        cmd_args = { file_name },
        title = "Pick diff base",
        layout = M.get_layout(),
        confirm = callback and function(picker, item)
            on_ref_confirm(picker, item, callback)
        end or nil,
    }

    Snacks.picker.git_log(git_log_opts)
end

function M.toggle_buf_staging(bufnr)
    gitsigns = gitsigns or require("gitsigns")
    gitsigns_cache = gitsigns_cache or require("gitsigns.cache")

    UT.async_run(function()
        UT.await(gitsigns.refresh)
        local entry = gitsigns_cache.cache[bufnr]
        if not entry then
            return
        end

        --- @type Gitsigns.Hunk.Hunk[]
        if #(entry.hunks or {}) > 0 then
            gitsigns.stage_buffer()
        else
            gitsigns.reset_buffer_index()
        end
    end)
end

--- Selects the hunk under the cursor, preferring unstaged hunks and falling
--- back to staged ones. Bultin `gitsigns.select_hunk()` only looks at
--- unstaged hunks.
--- @param greedy boolean Select contiguous hunks (see 'diff_opts.linematch').
--- @return nil
function M.select_hunk(greedy)
    gitsigns_cache = gitsigns_cache or require("gitsigns.cache")
    gitsigns_async = gitsigns_async or require("gitsigns.async")

    local entry = gitsigns_cache.cache[vim.api.nvim_get_current_buf()]
    if not entry then
        return
    end

    local hunk = gitsigns_async
        .run(function()
            --- @diagnostic disable-next-line: return-type-mismatch annontations for `run` do not match the return type of `get_hunk`
            return entry:get_hunk(nil, greedy, false)
                or entry:get_hunk(nil, greedy, true)
        end)
        :wait()

    if not hunk then
        return
    end

    local start, vend = hunk.added.start, hunk.vend
    if vim.fn.mode():find("v") then
        vim.cmd(("normal! %dGoV%dG"):format(start, vend))
    else
        vim.cmd(("normal! %dGV%dG"):format(start, vend))
    end
end

--- @type Gitsigns.NavOpts
local nav_opts = { target = "all" }

--- Builds a keymap callback that navigates between git hunks,
--- falling back to the builtin diff motions inside a diff window.
--- @param direction "next" | "prev"
--- @return fun(): string
function M.nav_hunk(direction)
    return function()
        if vim.wo.diff then
            return direction == "next" and "]c" or "[c"
        end

        vim.schedule(function()
            gitsigns = gitsigns or require("gitsigns")
            gitsigns.nav_hunk(direction, nav_opts)
        end)
        return "<Ignore>"
    end
end

--- Resolves the Neogit repo instance for a file (or cwd).
--- Notifies and returns nil outside a git worktree.
--- @param file_name? string
--- @return NeogitRepo|nil
local function repo_for_file(file_name)
    local dir = file_name and vim.fs.dirname(vim.fs.abspath(file_name))
        or vim.uv.cwd()
    local repo = require("neogit.lib.git.repository").instance(dir)

    if repo.worktree_root == "" then
        return nil
    end

    return repo
end

--- Awaits a full repo refresh. Must run inside a neogit async context.
--- @param repo NeogitRepo
--- @param source string Refresh source label for Neogit logs.
local function await_refresh(repo, source)
    require("neogit.lib.async").wrap(
        function(cb) repo:dispatch_refresh({ source = source, callback = cb }) end,
        1
    )()
end

--- Opens a picker over the file's git log so the user can choose a base
--- commit to diff against. Resolves the file's repo, refreshes it, then
--- marks HEAD from Neogit repo state. Notifies and aborts outside a
--- git worktree.
--- @param file_name? string optional file name to query log against
--- @param callback? fun(hash: string) Invoked with the chosen commit hash, use
--- nil to use Snacks.picker.git_log default on_confirm action
--- @return nil
function M.git_log_picker(file_name, callback)
    require("neogit.lib.async").void(function()
        local repo = repo_for_file(file_name)
        if not repo then
            vim.notify(
                "Not a git repository",
                vim.log.levels.WARN,
                { title = "Diff" }
            )
            return
        end

        await_refresh(repo, "diff-base-picker")
        open_log_picker(repo.state.head.oid or "", file_name, callback)
    end)()
end

return M
