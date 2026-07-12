local term_buf = nil

local function toggle_terminal()
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_buf_delete(term_buf, { force = true })
        term_buf = nil
    else
        vim.cmd("split | term")
        term_buf = vim.api.nvim_get_current_buf()
    end
end

map_toggle_key("t", toggle_terminal, "Bottom Terminal Pane")
