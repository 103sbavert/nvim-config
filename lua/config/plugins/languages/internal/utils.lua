local M = {}

--- @param key string
--- @param lsp_config LspKeyConfig
--- @param client vim.lsp.Client
--- @param bufnr integer
local function map_if_capable(key, lsp_config, client, bufnr)
    -- Gate initial mapping on the attaching client, but resolve live
    -- clients at invoke time so re-attach (e.g. dynamic registration)
    -- never leaves a keymap bound to a stale client object.
    if
        lsp_config.capability
        and not client:supports_method(lsp_config.capability, bufnr)
    then
        return
    end

    local capability = lsp_config.capability

    vim.keymap.set(lsp_config.modes or "n", key, function()
        local live
        if capability then
            live = vim.lsp.get_clients({ bufnr = bufnr, method = capability })
        else
            live = vim.lsp.get_clients({ bufnr = bufnr })
        end

        if #live == 0 then
            vim.notify(
                string.format(
                    "%s: no attached client supports this buffer",
                    lsp_config.description
                ),
                vim.log.levels.WARN
            )
            return
        end

        lsp_config.jump_action(bufnr)
    end, { buffer = bufnr, desc = lsp_config.description })
end

local lsp_jump =
    require("config.plugins.languages.internal.lsp-actions").lsp_jump

--- @param client vim.lsp.Client
--- @param bufnr integer
function M.map_lsp_actions(client, bufnr)
    for key, config in pairs(lsp_jump) do
        if config.jump_action then
            map_if_capable(key, config, client, bufnr)
        end
    end
end

--- Returns effective indent size for bufnr: buffer-local shiftwidth (or tabstop
--- when shiftwidth=0), cascading to global, with 4 as final safety fallback.
--- @param bufnr integer The buffer handle/number to evaluate.
--- @return integer indent_size The resolved shiftwidth or tabstop indent level.
function M.get_indent(bufnr)
    local sw = vim.bo[bufnr].shiftwidth
    if sw ~= 0 then
        return sw
    end
    -- shiftwidth=0 means "use tabstop"
    local ts = vim.bo[bufnr].tabstop
    if ts ~= 0 then
        return ts
    end
    return 4
end

--- Checks if the given workspace root contains a dedicated Lua configuration file.
--- @param workspace_folders? table[] List of workspace folders provided by the LSP client.
--- @return boolean has_config True if `.luarc.json` or `.luarc.jsonc` exists in the workspace root.
function M.has_lua_config(workspace_folders)
    if workspace_folders and #workspace_folders > 0 then
        local dir_path = workspace_folders[1].name

        return (
            vim.uv.fs_stat(dir_path .. "/.luarc.json") ~= nil
            or vim.uv.fs_stat(dir_path .. "/.luarc.jsonc") ~= nil
        )
    end
    return false
end

--- Determines whether the workspace root matches the active Neovim configuration directory.
--- @param workspace_folders? table[] List of workspace folders provided by the LSP client.
--- @return boolean is_nvim True if the workspace path matches standard Neovim config path.
function M.is_nvim_config(workspace_folders)
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
function M.get_nvim_lua_opts(base_ls_opts)
    if not base_ls_opts or type(base_ls_opts) ~= "table" then
        return vim.deepcopy(nvim_lua_opts)
    end

    return vim.tbl_deep_extend("force", {}, base_ls_opts, nvim_lua_opts)
end

return M
