local term_buf = nil
local term_win = nil

--- Toggles terminal visibility if a valid buffer already exists, creates and
--- presents new buffer if none
local function toggle_terminal()
    -- Hide terminal if window is open and valid
    if term_win and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, false)
        term_win = nil
        return
    end

    -- Re-open window if valid buffer exists
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        term_win = vim.api.nvim_open_win(term_buf, true, { split = "below" })
        return
    end

    -- Create new buffer and terminal job if no valid buffer exists
    term_buf = vim.api.nvim_create_buf(false, false)
    term_win = vim.api.nvim_open_win(term_buf, true, { split = "below" })

    vim.bo[term_buf].modifiable = false

    local chan_id = vim.fn.jobstart({ vim.o.shell }, { term = true })
    if chan_id <= 0 then
        vim.notify("Unable to open the terminal", vim.log.levels.ERROR)
    end
end

map_toggle_key("t", toggle_terminal, "Bottom Terminal Pane")
