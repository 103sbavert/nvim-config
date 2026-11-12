local M = {}

--- Checks if the given workspace root contains a dedicated Lua configuration file.
--- @param workspace_folders? table[]|string List of workspace folders provided by the LSP client.
--- @return boolean has_config True if `.luarc.json` or `.luarc.jsonc` exists in the workspace root.
function M.has_lua_config(workspace_folders)
    --- @type string
    local dir_path

    if type(workspace_folders) == "string" then
        dir_path = workspace_folders
    elseif
        workspace_folders
        and type(workspace_folders) == "table"
        and #workspace_folders > 0
    then
        dir_path = workspace_folders[1].name
    else
        return false
    end

    return (
        vim.uv.fs_stat(dir_path .. "/.luarc.json") ~= nil
        or vim.uv.fs_stat(dir_path .. "/.luarc.jsonc") ~= nil
    )
end

--- Determines whether the workspace root matches the active Neovim configuration directory.
--- @param workspace_folders? table[] List of workspace folders provided by the LSP client.
--- @return boolean is_nvim True if the workspace path matches standard Neovim config path.
local function is_nvim_config(workspace_folders)
    if workspace_folders and #workspace_folders > 0 then
        local dir_path = workspace_folders[1].name

        return dir_path == vim.fn.stdpath("config")
    end

    return false
end

--- @type vim.lsp.Config
local nvim_lua_opts = {
    runtime = {
        version = "LuaJIT",
        path = { "lua/?.lua", "lua/?/init.lua" },
    },
    workspace = {
        checkThirdParty = false,
        library = {
            vim.env.VIMRUNTIME,
            vim.fn.stdpath("config"),
            vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt"),
            vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
        },
    },
}

--- Merges Neovim development environment settings into existing Lua language server options.
--- @param base_ls_opts? table Existing Lua settings table to extend.
--- @return table merged_opts Deeply merged LSP settings table prioritizing Neovim config paths.
local function get_nvim_lua_opts(base_ls_opts)
    if not base_ls_opts or type(base_ls_opts) ~= "table" then
        return vim.deepcopy(nvim_lua_opts)
    end

    return vim.tbl_deep_extend("force", {}, base_ls_opts, nvim_lua_opts)
end

--- @param client vim.lsp.Client
local function on_init(client)
    if
        vim.g.lazy_lua_ls
        or not is_nvim_config(client.workspace_folders)
        or M.has_lua_config(client.workspace_folders)
    then
        return
    end

    local base_ls_opts = client.config.settings.Lua

    --- @cast base_ls_opts table
    client.config.settings.Lua =
        get_nvim_lua_opts(base_ls_opts)
end

--- @type vim.lsp.Config
M.lsp_config = {
    on_init = on_init,
    settings = {
        Lua = {
            format = { enable = false },
            diagnostics = { disable = { "missing-fields" } },
        },
    },
}

return M
