--- @class LspKeyConfig
--- @field action fun(bufnr: integer) Callback executed for standard language servers.
--- @field description string Documentation string for the keymap decoration.
--- @field capability? string Optional LSP method required to enable this keymap.
--- @field modes? string|string[] Optional mode override for this keymap or nil to use 'normal'.

local M = {}

local formatting = require("plugins.languages.internal.formatting")

-- LSP keybinds/actions with no Snacks dependency
--- @type table<string, LspKeyConfig>
local lsp_actions = {
    ["<leader>ln"] = {
        description = "Re[n]ame Symbol",
        action = function() return vim.lsp.buf.rename() end,
        capability = "textDocument/rename",
    },
    ["ga"] = {
        description = "Code [a]ction",
        action = function()
            return vim.lsp.buf.code_action({
                context = {
                    only = {
                        "",
                        "quickfix",
                        "refactor",
                        "refactor.extract",
                        "refactor.inline",
                        "refactor.move",
                        "refactor.rewrite",
                        "source",
                        "source.organizeImports",
                        "source.fixAll",
                    },
                },
            })
        end,
        capability = "textDocument/codeAction",
        modes = { "n", "v" },
    },
    ["<leader>f"] = {
        description = "[f]ormat buffer",
        modes = { "n", "v" },
        action = function()
            formatting.FormatBuffer(vim.api.nvim_get_current_buf(), true)
        end,
    },
}

--- @param key string
--- @param lsp_config LspKeyConfig
--- @param client vim.lsp.Client
--- @param bufnr integer
local function map_if_capable(key, lsp_config, client, bufnr)
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

        lsp_config.action(bufnr)
    end, { buffer = bufnr, desc = lsp_config.description })
end

--- @param client vim.lsp.Client
--- @param bufnr integer
function M.map_lsp_actions(client, bufnr)
    for key, config in pairs(lsp_actions) do
        if config.action then
            map_if_capable(key, config, client, bufnr)
        end
    end
end

return M
