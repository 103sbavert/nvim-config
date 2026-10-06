local show_hidden =
    require("plugins.snacks_nvim.utils").hidden_for_cwd(vim.fn.getcwd())

--- @type LazySpec
return {
    "folke/snacks.nvim",
    dependencies = {
        "esmuellert/codediff.nvim",
    },
    priority = 1000,
    lazy = false,
    keys = function()
        -- Get rid of keyboard LSP shortcuts I don't like
        vim.keymap.del("n", "grn")
        vim.keymap.del("n", "grx")
        vim.keymap.del({ "n", "x" }, "gra")
        vim.keymap.del("n", "grr")
        vim.keymap.del("n", "gri")
        vim.keymap.del("n", "grt")

        return require("plugins.snacks_nvim.keys")
    end,
    --- @type snacks.Config
    opts = {
        statuscolumn = {
            enabled = true,
        },
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
            actions = {
                ["start_insert"] = function() vim.cmd("startinsert!") end,
                ["show_diff"] = require("plugins.snacks_nvim.git").git_show_diff,
            },
            win = {
                input = {
                    keys = {
                        ["/"] = {
                            "start_insert",
                            mode = { "n" },
                            desc = "Start insert",
                        },
                        ["<ESC>"] = {
                            "focus_list",
                            mode = { "i", "n" },
                            desc = "Focus list",
                        },
                    },
                },
                list = {
                    keys = {
                        ["/"] = {
                            "focus_input",
                            mode = { "n" },
                            desc = "Focus input",
                        },
                        ["<ESC>"] = {
                            "close",
                            mode = { "n", "i" },
                            desc = "Close picker",
                        },
                    },
                },
            },
            layouts = {
                ["git_log"] = require("plugins.snacks_nvim.git").git_log_layout,
            },
            sources = {
                buffers = {
                    matcher = {
                        cwd_bonus = true,
                        frecency = true,
                        sort_empty = true,
                    },
                    transform = "unique_file",
                    hidden = true,
                    ignored = true,
                },
                git_status = {
                    layout = {
                        preset = "git_log",
                    },
                },
                git_log_file = {
                    confirm = "show_diff",
                    layout = {
                        preset = "git_log",
                    },
                },
                git_log = {
                    layout = {
                        preset = "git_log",
                    },
                },
                files = {
                    hidden = show_hidden,
                    ignored = true,
                },
                lsp_symbols = {
                    filter = {
                        ["lua"] = true,
                    },
                },
                explorer = {
                    auto_close = true,
                    hidden = show_hidden,
                    sort = { fields = { "#text:inc" } },
                    focus = "input",
                    tree = false,
                    actions = {
                        ["explorer_toggle_tree"] = function(p)
                            --- @diagnostic disable-next-line: inject-field
                            p.opts.tree = not p.opts.tree
                            p:refresh()
                        end,
                    },
                    win = {
                        input = {
                            keys = {
                                ["<C-t>"] = {
                                    "explorer_toggle_tree",
                                    mode = { "i", "n" },
                                    desc = "Toggle tree mode",
                                },
                            },
                        },
                    },
                },
            },
        },
        notify = {
            enabled = true,
        },
        notifier = {
            enabled = true,
            style = "compact",
        },
        quickfile = { enabled = true },
        scope = { enabled = true },
        terminal = { enabled = true },
        scroll = { enabled = true },
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
    config = function(_, opts)
        require("snacks").setup(opts)

        -- INFO: Patch `snacks.picker.source.lsp.request` to display a spinner
        -- notification while awaiting the LSP response.
        local lsp_source = require("snacks.picker.source.lsp")

        ---@diagnostic disable-next-line: duplicate-set-field
        lsp_source.request =
            require("plugins.snacks_nvim.utils").custom_lsp_request(
                lsp_source.request
            )

        require("plugins.snacks_nvim.autocmds")
    end,
}
