vim.g.toggle_term = {
    buf = nil,
    win_id = nil,
}

local term_tracker = vim.g.toggle_term

local enter_group =
    vim.api.nvim_create_augroup("EnterTermGroup", { clear = true })

--- Toggles terminal visibility if a valid window already exists,
--- re-opens if buffer exists, or creates a new terminal buffer/job.
local function toggle_terminal()
    -- Hide terminal if window is open and valid
    if
        term_tracker.win_id
        and vim.api.nvim_win_is_valid(term_tracker.win_id)
    then
        vim.api.nvim_win_close(term_tracker.win_id, false)
        term_tracker.win_id = nil
        return
    end

    -- Re-open window if valid buffer exists
    if term_tracker.buf and vim.api.nvim_buf_is_valid(term_tracker.buf) then
        term_tracker.win_id =
            vim.api.nvim_open_win(term_tracker.buf, true, { split = "below" })
        vim.cmd("startinsert")
        return
    end

    -- Create new buffer and terminal job if no valid buffer exists
    term_tracker.buf = vim.api.nvim_create_buf(false, false)
    term_tracker.win_id =
        vim.api.nvim_open_win(term_tracker.buf, true, { split = "below" })

    local chan_id = vim.fn.jobstart({ vim.o.shell }, { term = true })
    if chan_id <= 0 then
        vim.notify("Unable to open the terminal", vim.log.levels.ERROR)
        return
    end

    vim.api.nvim_create_autocmd("BufEnter", {
        buf = term_tracker.buf,
        group = enter_group,
        callback = function()
            if vim.fn.mode() ~= "t" then
                vim.cmd("startinsert")
            end
        end,
    })

    vim.cmd("startinsert")
end

vim.keymap.set(
    { "n", "o", "t", "x", "v" },
    "<C-/>",
    toggle_terminal,
    { desc = "Open terminal" }
)
