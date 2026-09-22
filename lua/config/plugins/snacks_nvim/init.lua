--- @type LazySpec
return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = function()
        local pickers = require("config.plugins.snacks_nvim.pickers")
        return vim.list_extend(pickers, {
            {
                "<C-/>",
                function() Snacks.terminal.toggle() end,
                desc = "Toggle Terminal",
            },
        })
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
            win = {
                input = {
                    keys = {
                        -- always re-enter search insert mode when pressing "/"
                        -- regardless of focused window
                        ["/"] = function() vim.cmd("startinsert") end,
                        mode = { "n" },
                    },
                },
            },
            sources = {
                buffers = {
                    hidden = true,
                },
                explorer = {
                    hidden = true,
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

            -- NOTE: The request appears to be synchronous, so the right place
            -- to clear the notif would be after the request is invoked

            -- local og_cb = function(...)
            --     vim.schedule(function() Snacks.notifier.hide(spinner_id) end)
            --     cb(...)
            -- end

            og_request(buf, method, params, cb)

            vim.schedule(function() Snacks.notifier.hide(spinner_id) end)
        end
    end,
}
