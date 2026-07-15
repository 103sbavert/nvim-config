return {
    "neovim/nvim-lspconfig",
    dependencies = {
        {
            "saghen/blink.cmp",
            version = "1.*",
        },
        "config.mason",
        "Hoffs/omnisharp-extended-lsp.nvim",
        "nvim-telescope/telescope.nvim",
        "folke/which-key.nvim",
        "stevearc/conform.nvim",
        "L3MON4D3/LuaSnip",
    },
    config = function()
        local csharp_lsp_extension = require("omnisharp_extended")
        -- Enable the following language servers
        --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
        --  See `:help lsp-config` for information about keys and how to configure
        ---@type table<string, vim.lsp.Config>
        local server_configs = {
            omnisharp = {
                handlers = {
                    ["textDocument/definition"] = csharp_lsp_extension.definition_handler,
                    ["textDocument/typeDefinition"] = csharp_lsp_extension.type_definition_handler,
                    ["textDocument/references"] = csharp_lsp_extension.references_handler,
                    ["textDocument/implementation"] = csharp_lsp_extension.implementation_handler,
                },
                settings = {
                    FormattingOptions = {
                        EnableEditorConfigSupport = true,
                        OrganizeImports = true,
                    },
                    RoslynExtensionsOptions = {
                        EnableAnalyzersSupport = true,
                        EnableImportCompletion = true,
                        EnableDecompilationSupport = true,
                    },
                },
            },
            gopls = {
                settings = {
                    gopls = {
                        hints = {
                            assignVariableTypes = true,
                            compositeLiteralFields = true,
                            compositeLiteralTypes = true,
                            constantValues = true,
                            functionTypeParameters = true,
                            parameterNames = true,
                            rangeVariableTypes = true,
                        },
                        analyses = {
                            unusedparams = true,
                        },
                        staticcheck = true,
                    },
                },
            },
            pyright = {},
            stylua = {},
            lua_ls = {
                on_init = function(client)
                    client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if
                            path ~= vim.fn.stdpath("config")
                            and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
                        then
                            return
                        end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                        runtime = {
                            version = "LuaJIT",
                            path = { "lua/?.lua", "lua/?/init.lua" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
                            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
                            library = vim.tbl_extend("force", vim.api.nvim_get_runtime_file("", true), {
                                "${3rd}/luv/library",
                                "${3rd}/busted/library",
                            }),
                        },
                    })
                end,
                ---@type lspconfig.settings.lua_ls
                settings = {
                    Lua = {
                        format = { enable = false }, -- Disable formatting (formatting is done by stylua)
                    },
                },
            },
        }

        local server_names = vim.tbl_keys(server_configs or {})
        require("config.mason").InstallTools(server_names)

        for name, server in pairs(server_configs) do
            vim.lsp.config(name, server)
            vim.lsp.enable(name)
        end

        require("config.plugins.lsp.actions")
        require("config.plugins.lsp.auto_commands")
        require("config.plugins.lsp.formatting")
        require("config.plugins.lsp.autocomplete")
    end,
}
