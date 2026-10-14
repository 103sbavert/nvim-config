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

--- Mason bin dir. Binaries resolving under it are mason-managed, not system.
local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")

--- @type table<string, string>|false|nil
local lsp_to_pkg
--- @type table<string, string>|false|nil
local dap_to_pkg

--- Resolve lspconfig server / nvim-dap adapter name to mason package name.
--- Mirrors mason-tool-installer `map_name`. Namespaces are disjoint so both
--- maps are checked sequentially.
--- @param name string
--- @return string
local function to_pkg(name)
    if lsp_to_pkg == nil then
        local ok, map = pcall(require, "mason-lspconfig.mappings")
        lsp_to_pkg = ok and map.get_mason_map().lspconfig_to_package or false
    end
    if dap_to_pkg == nil then
        local ok, dap = pcall(require, "mason-nvim-dap.mappings.source")
        dap_to_pkg = ok and dap.nvim_dap_to_package or false
    end
    if lsp_to_pkg then
        name = lsp_to_pkg[name] or name
    end
    if dap_to_pkg then
        name = dap_to_pkg[name] or name
    end
    return name
end

--- Binary names provided by a mason package (`spec.bin` keys).
--- Falls back to the package name when the registry is unavailable.
--- @param pkg string
--- @return string[]
local function get_bins(pkg)
    local ok_registry, registry = pcall(require, "mason-registry")
    if not ok_registry then
        return { pkg }
    end
    local ok, p = pcall(registry.get_package, to_pkg(pkg))
    if not ok or not p.spec.bin then
        return { pkg }
    end
    return vim.tbl_keys(p.spec.bin)
end

--- True if any provided binary resolves on PATH outside mason/bin.
--- @param pkg string
--- @return boolean
local function has_system_tool(pkg)
    for _, bin in ipairs(get_bins(pkg)) do
        if
            vim.fn.executable(bin) == 1
            and not vim.startswith(vim.fn.exepath(bin), mason_bin)
        then
            return true
        end
    end
    return false
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
            ensure_installed = vim.tbl_filter(
                function(tool)
                    return not has_system_tool(
                        type(tool) == "table" and tool[1] or tool
                    )
                end,
                cumulative_tool_names
            ),
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
