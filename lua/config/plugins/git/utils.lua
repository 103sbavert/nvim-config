local M = {}

-- Initialize mappers
--- Keymap group for git actions, mapped under "<leader>g".
M.git_key_mapper = create_keymap_group("<leader>g", { "n", "v" })
--- Keymap group for backward hunk/change navigation, mapped under "[".
M.navigate_bw_mapper = create_keymap_group("[", { "n", "v" })
--- Keymap group for forward hunk/change navigation, mapped under "]".
M.navigate_fw_mapper = create_keymap_group("]", { "n", "v" })

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
--- Cached Snacks formatter refs, resolved lazily on first picker render so
--- this module never indexes the `Snacks` global at load time.
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

--- Cached layout config for Snacks.picker.git_log using default options but
--- with a wider preview and fullscreen window
--- @type snacks.picker.layout.Config
local log_layout = nil

--- @return snacks.picker.layout.Config
local function get_log_layout()
    if log_layout then
        return log_layout
    end

    log_layout = vim.deepcopy(require("snacks.picker.config.layouts").default)

    log_layout.fullscreen = true
    log_layout.layout.border = true

    for _, prop in ipairs(log_layout.layout) do
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

    return log_layout
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
        layout = get_log_layout(),
        confirm = callback and function(picker, item)
            on_ref_confirm(picker, item, callback)
        end or nil,
    }

    Snacks.picker.git_log(git_log_opts)
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
        vim.notify(
            "Not a git repository",
            vim.log.levels.WARN,
            { title = "Diff" }
        )
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
            return
        end

        await_refresh(repo, "diff-base-picker")
        open_log_picker(repo.state.head.oid or "", file_name, callback)
    end)()
end

return M
