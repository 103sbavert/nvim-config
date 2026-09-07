--- @class LspKeyConfig
--- @field jump_action function(bufnr?: integer) Callback
--- function executed for standard language servers.
--- @field description string Documentation string for the keymap decoration.
--- @field capability? string Optional LSP method required to enable this keymap.
--- @field modes? string|string[] Optional mode override for this keymap or nil to use 'normal'

local M = {}

-- LSP keybinds/actions with no Snacks dependency
--- @type table<string, LspKeyConfig>
M.lsp_jump = {
    ["<leader>ln"] = {
        description = "Re[n]ame Symbol",
        jump_action = function() return vim.lsp.buf.rename() end,
        capability = "textDocument/rename",
    },
    ["ga"] = {
        description = "Code [a]ction",
        jump_action = function()
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
}

return M
