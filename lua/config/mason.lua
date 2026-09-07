local M = {}

require("mason").setup({})

local installer = require("mason-tool-installer")

local cumulative_tool_tbl = {}
local debounce_hrs = 6

--- @param tool_list string[]
M.InstallTools = function(tool_list)
    vim.list_extend(cumulative_tool_tbl, tool_list)
end

local group =
    vim.api.nvim_create_augroup("mason-install-tools", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        installer.setup({
            ensure_installed = cumulative_tool_tbl,
            debounce_hours = debounce_hrs,
            integrations = {
                ["mason-lspconfig"] = true,
                ["mason-nvim-dap"] = true,
            },
            run_on_start = true,
        })

        vim.defer_fn(function() installer.check_install(true, false) end, 1000)
    end,
})

return M
