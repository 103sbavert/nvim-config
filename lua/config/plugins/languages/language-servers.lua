--- @type LazySpec
return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "config.mason",
            "config.utils",
            "j-hui/fidget.nvim",
        },
        config = function()
            local lang_utils =
                require("config.plugins.languages.internal.utils")

            -- NOTE: roslyn.nvim enables "roslyn" server on its own (see:
            -- plugin/roslyn.lua), so the LSP can stay out of this map.

            -- Enable the following language servers
            --- @type table<string, vim.lsp.Config>
            local server_config_map = {
                phpactor = {},
                tinymist = {},
                vtsls = {},
                eslint = {},
                bashls = {},
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            semanticTokens = true,
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
                                shadow = true,
                            },
                            staticcheck = true,
                        },
                    },
                },
                gitlab_ci_ls = {},
                pyright = {},
                stylua = {},
                lua_ls = {
                    on_attach = function(client)
                        client.server_capabilities.documentFormattingProvider =
                            false
                        client.server_capabilities.documentRangeFormattingProvider =
                            false
                    end,
                    on_init = function(client)
                        if
                            not lang_utils.is_nvim_config(
                                client.workspace_folders
                            )
                            and lang_utils.has_lua_config(
                                client.workspace_folders
                            )
                        then
                            return
                        end

                        local base_ls_opts = client.config.settings.Lua
                        --- @cast base_ls_opts table
                        client.config.settings.Lua =
                            lang_utils.get_nvim_lua_opts(base_ls_opts)
                    end,
                    settings = {
                        Lua = {
                            format = { enable = false },
                            diagnostics = { disable = { "missing-fields" } },
                        },
                    },
                },
            }

            local server_names = vim.tbl_keys(server_config_map or {})

            -- NOTE: only install as the configuration is handled externally, like config below
            local managed = { "roslyn_ls" }
            vim.list_extend(server_names, managed)

            require("config.mason").InstallTools(server_names)
            require("config.plugins.languages.internal.autocmds")

            for name, server_conf in pairs(server_config_map) do
                vim.lsp.config(name, server_conf)
                vim.lsp.enable(name)
            end
        end,
    },
    {
        "seblyng/roslyn.nvim",
        ft = { "cs", "razor", "msbuild_proj", "solution" },
        init = function()
            vim.filetype.add({
                extension = {
                    csproj = "msbuild_proj",
                    fsproj = "msbuild_proj",
                    vbproj = "msbuild_proj",
                    props = "msbuild_proj",
                    targets = "msbuild_proj",
                    slnx = "solution",
                    nuspec = "xml",
                },
            })
        end,
        ---@module "roslyn.config"
        ---@type RoslynNvimConfig
        opts = {
            lock_target = true,
        },
    },
}
