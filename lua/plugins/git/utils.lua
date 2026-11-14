local M = {}

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

--- Returns the hunk closest to `lnum` and its distance in lines.
--- @param hunks table[]?
--- @param lnum integer
--- @return table? hunk
--- @return integer? dist
local function nearest_hunk(hunks, lnum)
    local best, best_dist
    for _, hunk in ipairs(hunks or {}) do
        local dist
        if lnum < hunk.added.start then
            dist = hunk.added.start - lnum
        elseif lnum > hunk.vend then
            dist = lnum - hunk.vend
        else
            dist = 0
        end

        if not best_dist or dist < best_dist then
            best, best_dist = hunk, dist
        end
    end
    return best, best_dist
end

--- Yields the async task for `ms` without blocking the event loop.
--- @param ms integer
local function sleep(ms)
    gitsigns_async = gitsigns_async or require("gitsigns.async")

    gitsigns_async.await(
        2,
        function(duration, cb) vim.defer_fn(cb, duration) end,
        ms
    )
end

--- Waits up to one second for gitsigns to populate a hunk list.
--- @param entry table
--- @param staged boolean
--- @return boolean
local function wait_for_hunks(entry, staged)
    if staged and not require("gitsigns.config").config.signs_staged_enable then
        return false
    end

    local key = staged and "hunks_staged" or "hunks"
    for _ = 1, 10 do
        if entry[key] ~= nil then
            return true
        end
        sleep(100)
    end
    return entry[key] ~= nil
end

--- @param entry table
--- @param greedy boolean
--- @param staged boolean
--- @param lnum integer
--- @return table? hunk
--- @return integer? dist
local function closest_hunk(entry, greedy, staged, lnum)
    if not wait_for_hunks(entry, staged) then
        return
    end
    return nearest_hunk(entry:get_hunks(greedy, staged), lnum)
end

--- Picks the closest hunk, preferring unstaged ones on equal distance.
--- @param entry table
--- @param greedy boolean
--- @param lnum integer
--- @return table? hunk
local function pick_hunk(entry, greedy, lnum)
    local hunk, dist = closest_hunk(entry, greedy, false, lnum)

    -- Staged hunks are only considered when the cursor is not already on an
    -- unstaged one.
    if hunk and dist == 0 then
        return hunk
    end

    local staged_hunk, staged_dist = closest_hunk(entry, greedy, true, lnum)
    if staged_hunk and (not hunk or staged_dist < dist) then
        return staged_hunk
    end
    return hunk
end

--- Visually selects the lines a hunk spans, extending the current selection
--- when called from visual mode.
--- @param hunk table
local function select_hunk_lines(hunk)
    local start, vend = hunk.added.start, hunk.vend
    if vim.fn.mode():find("v") then
        vim.cmd(("normal! %dGoV%dG"):format(start, vend))
    else
        vim.cmd(("normal! %dGV%dG"):format(start, vend))
    end
end

--- Selects the hunk under the cursor, preferring unstaged hunks and falling
--- back to staged ones. Builtin `gitsigns.select_hunk()` only looks at unstaged
--- hunks. Falls back to the nearest hunk in the buffer.
--- @param greedy boolean Select contiguous hunks (see 'diff_opts.linematch').
--- @return nil
function M.select_hunk(greedy)
    gitsigns_cache = gitsigns_cache or require("gitsigns.cache")
    local entry = gitsigns_cache.cache[vim.api.nvim_get_current_buf()]

    if not entry then
        return
    end

    gitsigns_async = gitsigns_async or require("gitsigns.async")

    local hunk = gitsigns_async
        .run(function()
            --- @diagnostic disable-next-line: return-type-mismatch annotations for `run` do not match the return type of `pick_hunk`
            return pick_hunk(entry, greedy, vim.api.nvim_win_get_cursor(0)[1])
        end)
        :wait()

    if hunk then
        select_hunk_lines(hunk)
    end
end

--- Builds a keymap callback that navigates between git hunks,
--- falling back to the builtin diff motions inside a diff window.
--- @param direction "next" | "prev"
--- @return fun(): string
function M.nav_hunk(direction)
    return function()
        if vim.wo.diff then
            return direction == "next" and "]c" or "[c"
        end

        vim.cmd("Gitsigns " .. direction .. "_hunk --target=all")
        return "<Ignore>"
    end
end

return M
