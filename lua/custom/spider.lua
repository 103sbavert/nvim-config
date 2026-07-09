--- Toggles buffer-local sub-word (camelCase/snake_case) motions via nvim-spider.
local function toggle_buffer_camel_mode()
    -- Initialize state variables and scope context to the active buffer.
    local bufnr = vim.api.nvim_get_current_buf()
    local is_active = vim.b[bufnr].camel_mode_active or false
    local modes = { "n", "o", "x" }

    if not is_active then
        vim.b[bufnr].camel_mode_active = true
        vim.notify("Enabling camelCase mode")

        vim.keymap.set(modes, "w", function() require("spider").motion("w") end, { buffer = bufnr, desc = "Spider-w" })
        vim.keymap.set(modes, "b", function() require("spider").motion("b") end, { buffer = bufnr, desc = "Spider-b" })
        vim.keymap.set(modes, "e", function() require("spider").motion("e") end, { buffer = bufnr, desc = "Spider-e" })
    else
        vim.b[bufnr].camel_mode_active = false
        vim.notify("Disabling camelCase mode")

        vim.keymap.del(modes, "w", { buffer = bufnr })
        vim.keymap.del(modes, "b", { buffer = bufnr })
        vim.keymap.del(modes, "e", { buffer = bufnr })
    end
end

-- toggle on demand
vim.keymap.set("n", "<leader>tc", toggle_buffer_camel_mode, { desc = "Toggle Buffer CamelCase Mode" })
