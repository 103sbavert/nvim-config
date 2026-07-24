return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "config.mason",
        { "seblyng/roslyn.nvim", lazy = true },
        "nvim-telescope/telescope.nvim",
        "folke/which-key.nvim",
        "L3MON4D3/LuaSnip",
    },
    config = function()
        local common_utils = require("config.utils")

        -- Enable the following language servers
        ---@type table<string, vim.lsp.Config>
        local server_config_map = {
            roslyn_ls = {
                on_attach = function(_, _)
                    require("roslyn").setup({
                        filewatching = "roslyn",
                        lock_target = true,
                    })
                end,
            },
            vtsls = {},
            shuck = {},
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
            lua_ls = {
                on_attach = function() common_utils.lazy_require("luasnip")().setup() end,
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
                            library = {
                                vim.env.VIMRUNTIME,
                                vim.fn.stdpath("config"),
                                vim.fs.joinpath(vim.env.XDG_DATA_HOME, "nvim/site/pack"),
                                vim.fs.joinpath(vim.env.XDG_DATA_HOME, "nvim/lazy"),
                            },
                        },
                    })
                end,
                settings = {
                    Lua = {
                        format = { enable = false },
                    },
                },
            },
        }

        local server_names = vim.tbl_keys(server_config_map or {})

        require("config.mason").InstallTools(server_names)

        require("config.plugins.lsp.actions")
        require("config.plugins.lsp.auto_commands")

        for name, server_conf in pairs(server_config_map) do
            vim.lsp.config(name, server_conf)
            vim.lsp.enable(name)
        end
    end,
}
