local M = {}

--- @module "gitsigns?"
local gitsigns = nil

--- @module "gitsigns.cache?"
local gitsigns_cache = nil

--- @module "gitsigns.async?"
local gitsigns_async = nil

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

--- Selects the hunk under the cursor, preferring unstaged hunks and falling
--- back to staged ones. Bultin `gitsigns.select_hunk()` only looks at unstaged
--- hunks.
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

return M
