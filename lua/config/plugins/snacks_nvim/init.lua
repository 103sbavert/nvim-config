--- @type LazySpec
return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    main = "snacks",
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
            },
        },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        statuscolumn = { enabled = true },
        terminal = { enabled = true },
        styles = {
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
    config = function(plugin, opts) require(plugin.main).setup(opts) end,
}
