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
        capability = "textDocument/formatting",
        action = function(bufnr) formatting.FormatBuffer(bufnr, true) end,
    },
}

--- @param capability? vim.lsp.protocol.Method.ClientToServer
--- @param bufnr? integer
--- @return boolean
local function has_clients(capability, bufnr)
    bufnr = (not bufnr or bufnr == 0) and vim.api.nvim_get_current_buf()
        or bufnr
    return #vim.lsp.get_clients({ bufnr = bufnr, method = capability }) > 0
end

--- @param bufnr integer
function M.sync_keymaps(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    for key, lsp_config in pairs(lsp_actions) do
        if lsp_config.action then
            if not has_clients(lsp_config.capability, bufnr) then
                pcall(vim.keymap.del, lsp_config.modes, key, { buffer = bufnr })
                return
            end

            vim.keymap.set(
                lsp_config.modes or "n",
                key,
                function() lsp_config.action(bufnr) end,
                { buffer = bufnr, desc = lsp_config.description }
            )
        end
    end
end

return M
