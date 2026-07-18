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
    local lspconfig_to_mason = require("mason-lspconfig").get_mappings().lspconfig_to_package
    local mason_names = vim.tbl_map(function(name) return lspconfig_to_mason[name] or name end, tool_list)

    vim.list_extend(cumulative_tool_tbl, mason_names)

    installer.setup({
        ensure_installed = cumulative_tool_tbl,
        debounce_hours = debounce_hrs,
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
