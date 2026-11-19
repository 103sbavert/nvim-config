--- @type LazySpec
return {
    "folke/noice.nvim",
    --- @module "noice.config"
    --- @type NoiceConfig
    opts = {
        lsp = {
            hover = { enabled = true },
            progress = { enabled = false },
            message = { enabled = false },
            signature = { enabled = false },
        },
        popupmenu = { enabled = false },
        notify = { enabled = false },
        presets = {
            long_message_to_split = true,
        },
        commands = {
            all = {
                view = "split",
                opts = { enter = true, format = "details" },
                filter = {
                    ["not"] = {
                        event = {
                            "msg_showcmd",
                            "msg_show.search_cmd",
                            "msg_ruler",
                        },
                    },
                },
            },
        },
        routes = {
            {
                view = "shell_display",
                filter = {
                    event = "msg_show",
                    kind = {
                        "shell_cmd",
                        "shell_out",
                        "shell_err",
                    },
                },
            },
        },
        views = {
            cmdline_popup = {
                position = { row = "100%", col = "0%" },
                size = { width = "100%", height = "auto" },
                border = { style = "none", padding = { 0, 0 } },
                win_options = {
                    winhighlight = {
                        Normal = "NormalFloat",
                    },
                },
            },
            confirm = {
                border = {
                    style = "rounded",
                    padding = { 0, 0 },
                },
                size = {
                    width = "auto",
                    height = "auto",
                },
                position = { row = "8%", col = "50%" },
            },
            cmdline_input = {
                border = {
                    style = "rounded",
                    padding = { 0, 0 },
                },
                size = {
                    width = "auto",
                    height = "auto",
                },
                position = { row = "8%", col = "50%" },
            },
            hover = {
                win_options = {
                    winhighlight = {
                        Normal = "NormalFloat",
                        FloatBorder = "FloatBorder",
                    },
                },
            },
            -- Custom views
            shell_display = {
                view = "split",
                size = { height = "40%" },
                enter = true,
                close = {
                    events = { "BufLeave" },
                    keys = { "<CR>", "q", "<Esc>" },
                },
                win_options = {
                    relativenumber = false,
                    number = false,
                },
                buf_options = {
                    filetype = "noice_shell_split",
                    buftype = "nofile",
                    bufhidden = "wipe",
                },
                format = { "{shell_display}" },
            },
        },
    },
    config = function(_, opts)
        local Formatters = require("noice.text.format.formatters")

        Formatters.shell_display = function(message, fmt_opts, input)
            if input.kind == "shell_cmd" and input.cmdline then
                Formatters.cmdline(message, fmt_opts)
            else
                Formatters.message(message, fmt_opts, input)
            end
        end

        require("noice").setup(opts)
    end,
}
