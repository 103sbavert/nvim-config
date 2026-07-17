local M = {}

require("mason-lspconfig").setup({
    automatic_enable = false,
})

require("mason").setup({})
local mason_tool_installer = require("mason-tool-installer")

local ensure_installed = {}
local debounce_hrs = 6

local InstallTools = function(tool_list)
    ensure_installed = vim.tbl_deep_extend("force", ensure_installed, tool_list)

    mason_tool_installer.setup({
        ensure_installed = ensure_installed,
        run_on_start = false,
    })
end

local group = vim.api.nvim_create_augroup("mason-install-tools", {
    clear = true,
})

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function() mason_tool_installer.check_install(true, false) end,
})

M.InstallTools = InstallTools

return M
