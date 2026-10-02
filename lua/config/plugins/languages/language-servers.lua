--- @type LazySpec
return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "config.utils",
            "j-hui/fidget.nvim",
        },
        config = function()
            -- NOTE: roslyn.nvim enables "roslyn" server on its own (see:
            -- plugin/roslyn.lua), so the LSP can stay out of this map.

            -- Enable the following language servers
            --- @type table<string, vim.lsp.Config>
            local server_config_map = {
                phpactor = {},
                tinymist = {
                    settings = {
                        formatterMode = "typstyle",
                        semanticTokens = "enabled",
                    },
                    before_init = function(_, config)
                        local font_paths =
                            require("config.utils").get_env_paths(
                                { config.root_dir, vim.fn.getcwd() },
                                ".typstrc",
                                "TYPST_FONT_PATHS"
                            )

                        if font_paths then
                            config.settings = config.settings or {}
                            config.settings.fontPaths = font_paths
                        end
                    end,
                },
                vtsls = {},
                eslint = {},
                bashls = {},
                markdown_oxide = {},
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
                        local lang_utils =
                            require("config.plugins.languages.internal.utils")

                        if
                            vim.g.lazy_lua_ls
                            or not lang_utils.is_nvim_config(
                                client.workspace_folders
                            )
                            or lang_utils.has_lua_config(
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

            MasonInstall(server_names)
            require("config.plugins.languages.internal.autocmds")

            for name, server_conf in pairs(server_config_map) do
                vim.lsp.config(name, server_conf)
                vim.lsp.enable(name)
            end
        end,
    },
    {
        "ymic9963/mdnotes.nvim",
        ft = { "markdown" },
        cmd = {
            "Mdn",
        },
        lazy = true,
        config = true,
    },
    {
        "brianhuster/live-preview.nvim",
        ft = { "markdown" },
        dependencies = {
            "folke/snacks.nvim",
        },
        lazy = true,
        config = true,
    },
    {
        "seblyng/roslyn.nvim",
        lazy = true,
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
        config = true,
    },
    {
        "chomosuke/typst-preview.nvim",
        ft = "typst",
        version = "1.*",
        lazy = true,
        config = true,
    },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                vim.env.VIMRUNTIME,
                vim.fs.joinpath(
                    vim.fn.stdpath("data"),
                    "site/pack/core/opt/lazy.nvim"
                ),
                {
                    path = vim.fs.joinpath(
                        vim.fn.stdpath("data"),
                        "site/pack/core/opt/bamboo.nvim"
                    ),
                    words = { "bamboo" },
                },
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
            enabled = function(root_dir)
                if vim.g.lazy_lua_ls then
                    return true
                end

                local lang_utils =
                    require("config.plugins.languages.internal.utils")

                return not lang_utils.has_lua_config(root_dir)
            end,
        },
    },
}
