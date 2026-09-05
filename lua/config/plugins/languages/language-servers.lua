--- @type LazySpec
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "config.mason",
        "seblyng/roslyn.nvim",
        "config.utils",
        "j-hui/fidget.nvim",
    },
    config = function()
        -- Enable the following language servers
        --- @type table<string, vim.lsp.Config>
        local server_config_map = {
            roslyn_ls = {
                before_init = function(_, _) require("roslyn").setup() end,
            },
            vtsls = {},
            bashls = {},
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
            gitlab_ci_ls = {},
            pyright = {},
            lua_ls = {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name

                        if
                            path ~= vim.fn.stdpath("config")
                            and (
                                vim.uv.fs_stat(path .. "/.luarc.json")
                                or vim.uv.fs_stat(path .. "/.luarc.jsonc")
                            )
                        then
                            return
                        end
                    end

                    local lua_settings = client.config.settings.Lua
                    --- @cast lua_settings table
                    client.config.settings.Lua =
                        vim.tbl_deep_extend("force", lua_settings, {
                            runtime = {
                                version = "LuaJIT",
                                path = { "lua/?.lua", "lua/?/init.lua" },
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = {
                                    vim.env.VIMRUNTIME,
                                    vim.fn.stdpath("config"),
                                    vim.fs.joinpath(
                                        vim.fn.stdpath("data"),
                                        "site/pack/core/opt"
                                    ),
                                    vim.fs.joinpath(
                                        vim.fn.stdpath("data"),
                                        "lazy"
                                    ),
                                },
                            },
                        })
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

        require("config.mason").InstallTools(server_names)

        require("config.plugins.languages.internal.lsp-actions")
        require("config.plugins.languages.internal.autocmds")

        for name, server_conf in pairs(server_config_map) do
            vim.lsp.config(name, server_conf)
            vim.lsp.enable(name)
        end
    end,
}
