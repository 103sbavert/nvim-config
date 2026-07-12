return {
    "neovim/nvim-lspconfig",
    dependencies = {
        {
            "saghen/blink.cmp",
            version = "1.*",
        },
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
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
        local servers = {
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

        -- Automatically install LSPs and related tools to stdpath for Neovim
        local mason = require("mason")
        mason.setup({})

        -- Ensure the servers and tools above are installed
        -- To check the current status of installed tools and/or manually install
        --      :Mason
        --
        -- To get more help help in this menu press
        --      g?
        local ensure_installed = vim.tbl_keys(servers or {})
        vim.list_extend(ensure_installed, {
            -- You can add other tools here that you want Mason to install
        })

        local mason_tool_installer = require("mason-tool-installer")
        mason_tool_installer.setup({ ensure_installed = ensure_installed, auto_update = true })

        for name, server in pairs(servers) do
            vim.lsp.config(name, server)
            vim.lsp.enable(name)
        end

        require("config.plugins.lsp.actions")
        require("config.plugins.lsp.auto_commands")
        require("config.plugins.lsp.formatting")
        require("config.plugins.lsp.autocomplete")
    end,
}
