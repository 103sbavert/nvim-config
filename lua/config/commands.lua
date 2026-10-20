-- [[ User commands ]]
-- Custom commands that do not utilize any external libraries or plugins

-- Copy the current buffer's absolute path to the system clipboard through the
-- configured clipboard provider.
--
-- See `:help provider`
vim.api.nvim_create_user_command("Copyfile", function()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then
        vim.notify("Copyfile: buffer has no file name", vim.log.levels.WARN)
        return
    end

    local path = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))

    vim.fn.setreg("+", path)

    vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Copy current buffer path" })
