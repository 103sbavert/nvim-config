local M = {}

require("mason-lspconfig").setup({
    automatic_enable = false,
})

require("mason").setup({})

local installer = require("mason-tool-installer")

local cumulative_tool_tbl = {}
local debounce_hrs = 6

---@param tool_list string[]
local InstallTools = function(tool_list)
    cumulative_tool_tbl = vim.tbl_deep_extend("force", cumulative_tool_tbl, tool_list)

    installer.setup({
        ensure_installed = cumulative_tool_tbl,
        run_on_start = false,
    })
end

local group = vim.api.nvim_create_augroup("mason-install-tools", {
    clear = true,
})

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function() installer.check_install(true, false) end,
})

M.InstallTools = InstallTools

return M
