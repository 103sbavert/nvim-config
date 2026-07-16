return {
    "Saghen/blink.cmp",
    version = "*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
        "neovim/nvim-lspconfig",
        "L3MON4D3/LuaSnip",
    },
    config = function()
        local blink = require("blink.cmp")

        blink.setup({
            keymap = {
                preset = "default",
            },
            cmdline = {
                enabled = true,
                keymap = {
                    preset = "default",
                },
                sources = { "buffer", "cmdline" },
                completion = {
                    trigger = {
                        show_on_blocked_trigger_characters = {},
                        show_on_x_blocked_trigger_characters = {},
                    },
                    list = { selection = { preselect = true, auto_insert = false } },
                    menu = { auto_show = true },
                    ghost_text = { enabled = false },
                },
            },
            appearance = {
                nerd_font_variant = "mono",
            },
            completion = {
                documentation = { auto_show = false, auto_show_delay_ms = 500 },
                menu = {
                    auto_show = true,
                },
                list = { selection = { preselect = true, auto_insert = false } },
            },
            sources = {
                default = { "lsp", "path", "snippets" },
            },
            snippets = { preset = "luasnip" },
            fuzzy = { implementation = "prefer_rust" },
            signature = { enabled = true },
        })

        local blink_grp = vim.api.nvim_create_augroup("blink_autocomp", { clear = true })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = blink_grp,
            callback = function(args)
                local client_id = args.data.client_id
                local client = vim.lsp.get_client_by_id(client_id)

                if client then
                    client.capabilities = require("blink.cmp").get_lsp_capabilities(client.capabilities)
                end
            end,
        })
    end,
}
