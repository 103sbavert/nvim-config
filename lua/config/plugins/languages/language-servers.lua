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
        "ymic9963/mdnotes.nvim",
        ft = { "markdown" },
        config = function(_, opts)
            require("mdnotes").setup(opts)

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = function(ev)
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(
                            mode,
                            lhs,
                            rhs,
                            { buffer = ev.buf, desc = desc }
                        )
                    end

                    map(
                        "n",
                        "gx",
                        "<cmd>Mdn inline_link open<CR>",
                        "Open inline link URI under cursor"
                    )
                    map(
                        "n",
                        "gf",
                        "<cmd>Mdn wikilink follow<CR>",
                        "Open markdown file from WikiLink"
                    )
                    map(
                        "n",
                        "gF",
                        "<cmd>Mdn wikilink follow_hor<CR>",
                        "Open markdown file from WikiLink in a horizontal split"
                    )
                    map(
                        "n",
                        "gr",
                        "<cmd>Mdn wikilink find_references<CR>",
                        "Show references of WikiLink or current buffer"
                    )
                    map(
                        "n",
                        "<leader>ln",
                        "<cmd>Mdn wikilink rename_references<CR>",
                        "Rename references of WikiLink or current buffer"
                    )
                    map(
                        { "n", "v" },
                        "lk",
                        "<cmd>Mdn inline_link toggle<CR>",
                        "Toggle inline link"
                    )
                    map(
                        "n",
                        "<C-o>",
                        "<cmd>Mdn history go_back<CR>",
                        "Go back to previously visited Markdown buffer"
                    )
                    map(
                        "n",
                        "<C-S-o>",
                        "<cmd>Mdn history go_forward<CR>",
                        "Go to next visited Markdown buffer"
                    )
                    map(
                        { "n", "v" },
                        "<leader>tf",
                        "<cmd>Mdn formatting strong_toggle<CR>",
                        "Toggle strong formatting"
                    )
                end,
            })
        end,
    },
    {
        "brianhuster/live-preview.nvim",
        ft = { "markdown" },
        dependencies = {
            "folke/snacks.nvim",
        },
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
    {
        "chomosuke/typst-preview.nvim",
        ft = "typst",
        jj2version = "1.*",
        lazy = true,
        config = function()
            assert(vim.fn.executable("typst"), "Typst CLI not found")

            local compile_typst = function(...)
                require("config.plugins.languages.internal.utils").compile_typst(
                    ...
                )
            end

            vim.api.nvim_create_user_command("TypstCompile", compile_typst, {
                nargs = "*",
                complete = "file",
                desc = "Compile provided file (default to current buffer)",
            })
        end,
    },
}
