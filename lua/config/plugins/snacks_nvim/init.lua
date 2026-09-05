--- @type LazySpec
return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = function()
        local pickers = require("config.plugins.snacks_nvim.pickers")
        return vim.list_extend(pickers, {
            {
                "<leader>tt",
                function() Snacks.terminal.toggle() end,
                desc = "[t]erminal",
            },
        })
    end,
    --- @type snacks.Config
    opts = {
        bigfile = { enabled = true },
        explorer = {
            enabled = true,
            replace_netrw = true,
            trash = true,
        },
        indent = { enabled = true },
        input = { enabled = true },
        picker = {
            enabled = true,
            sources = {
                explorer = {
                    hidden = true,
                },
                lsp_symbols = {
                    filter = {
                        ["lua"] = true,
                    },
                },
            },
        },
        notifier = {
            enabled = true,
            style = "compact",
        },
        quickfile = { enabled = true },
        scope = { enabled = true },
        terminal = { enabled = true },
        styles = {
            notification = {
                border = "rounded",
            },
            terminal = {
                keys = {
                    term_normal = {
                        "<C-n>",
                        "<C-\\><C-n>",
                        mode = "t",
                        expr = true,
                        desc = "Terminal normal",
                    },
                },
            },
        },
    },
    config = true,
}
