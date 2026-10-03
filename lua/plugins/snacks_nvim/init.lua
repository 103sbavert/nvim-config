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
                    hidden = true,
                    ignored = true,
                },
                lsp_symbols = {
                    filter = {
                        ["lua"] = true,
                    },
                },
                explorer = {
                    auto_close = true,
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

        local spinner = {
            "⠋",
            "⠙",
            "⠹",
            "⠸",
            "⠼",
            "⠴",
            "⠦",
            "⠧",
            "⠇",
            "⠏",
        }

        -- INFO: Patch `snacks.picker.source.lsp.request` to display a spinner
        -- notification while awaiting the LSP response.
        local lsp_source = require("snacks.picker.source.lsp")
        local og_request = lsp_source.request

        ---@diagnostic disable-next-line: duplicate-set-field
        lsp_source.request = function(buf, method, params, cb)
            local spinner_id = "await_lsp_" .. tostring(buf) .. method

            vim.schedule(function()
                Snacks.notifier.notify("Waiting for LSP", "info", {
                    id = spinner_id,
                    title = "Snacks picker",
                    timeout = false,
                    opts = function(notif)
                        notif.icon = spinner[math.floor(
                            vim.uv.hrtime() / (1e6 * 80)
                        ) % #spinner + 1]
                    end,
                })
            end)

            og_request(buf, method, params, cb)

            vim.schedule(function() Snacks.notifier.hide(spinner_id) end)
        end

        -- Sync disk modifications and refresh Snacks explorer
        local refresh_files_grp = vim.api.nvim_create_augroup(
            "SnacksRefreshFilesGroup",
            { clear = true }
        )

        local function refresh_explorer()
            if package.loaded["snacks"] then
                for _, picker in
                    ipairs(Snacks.picker.get({ source = "explorer" }))
                do
                    pcall(picker.find, picker)
                end
            end
        end

        vim.api.nvim_create_autocmd({ "TermClose", "TermLeave" }, {
            group = refresh_files_grp,
            callback = refresh_explorer,
        })

        vim.api.nvim_create_autocmd("FileType", {
            group = refresh_files_grp,
            pattern = { "gitcommit", "gitrebase" },
            callback = function(event)
                vim.api.nvim_create_autocmd("BufUnload", {
                    group = refresh_files_grp,
                    buffer = event.buf,
                    once = true,
                    callback = function() vim.schedule(refresh_explorer) end,
                })
            end,
        })
    end,
}
