require("noice").setup({
    lsp = {
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
        },
    },
    presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
    },
    routes = {
        {
            view = "split",
            filter = {
                event = "msg_show",
                kind = {
                    "shell_out",
                    "shell_err",
                },
            },
            opts = { enter = true },
        },
        {
            filter = {
                kind = "confirm",
                find = "chezmoi",
            },
            view = "chezmoi_confirm",
        },
    },
    views = {
        split = {
            enter = false,
            size = "auto",
        },
        cmdline_popup = {
            position = {
                row = 10,
                col = "50%",
            },
            size = {
                width = "25%",
                height = "auto",
            },
            border = {
                style = "rounded",
                padding = { 0, 1 },
            },
        },
        chezmoi_confirm = {
            view = "confirm",
            focusable = false,
            border = {
                text = {
                    top = " Chezmoi ",
                },
            },
        },
    },
})
