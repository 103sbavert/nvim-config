--- @type table<string, boolean>
local cumulative_tool_tbl = {}
--- @type string[]
local cumulative_tool_names = {}

--- Collect tools for mason-tool-installer. Runs at spec-require time so
--- other specs can call it in init/config without ordering hacks.
--- @param tool_list string[]
_G.MasonInstall = function(tool_list)
    for _, tool in ipairs(tool_list) do
        if not cumulative_tool_tbl[tool] then
            cumulative_tool_tbl[tool] = true
            table.insert(cumulative_tool_names, tool)
        end
    end
end

--- @type LazySpec
return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "jay-babu/mason-nvim-dap.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    event = "VimEnter",
    config = function(_, opts)
        require("mason").setup(opts)
        local installer = require("mason-tool-installer")

        installer.setup({
            ensure_installed = cumulative_tool_names,
            debounce_hours = vim.g.mason_debounce_hours or 6, -- default debounce period is 6 hours
            integrations = {
                ["mason-lspconfig"] = true,
                ["mason-nvim-dap"] = true,
            },
            run_on_start = true,
        })

        vim.defer_fn(function() installer.check_install(true, false) end, 6000)
    end,
}
