---@type LazySpec
return {
    "folke/noice.nvim",
    opts = {
        lsp = {
            hover = { enabled = true },
            progress = { enabled = false },
            message = { enabled = false },
            signature = { enabled = false },
        },
        override = {
            ["vim.ui.input"] = false,
            ["vim.ui.select"] = false,
        },
        popupmenu = { enabled = false },
        notify = { enabled = false },
        presets = {
            long_message_to_split = true,
        },
        routes = {
            {
                view = "shell_display",
                filter = {
                    event = "msg_show",
                    kind = { "shell_out", "shell_err" },
                },
            },
            {
                filter = { kind = "confirm", find = "chezmoi" },
                view = "chezmoi_confirm",
            },
        },
        views = {
            cmdline_popup = {
                position = { row = "100%", col = "0%" },
                size = { width = "100%", height = "auto" },
                border = { style = "none" },
                win_options = {
                    winhighlight = {
                        Normal = "CmdlineBackground",
                        FloatBorder = "ElevatedFloatBorder",
                    },
                },
            },
            hover = {
                win_options = {
                    winhighlight = {
                        Normal = "ElevatedFloatNormal",
                        FloatBorder = "ElevatedFloatBorder",
                    },
                },
            },
            shell_display = {
                view = "split",
                size = { height = "30%" },
                enter = true,
                close = { keys = { "<CR>", "q", "<Esc>" } },
                buf_options = {
                    filetype = "noice_shell_split",
                    buftype = "nofile",
                    bufhidden = "wipe",
                },
                format = { "{message}\n" },
            },
            chezmoi_confirm = {
                view = "confirm",
                focusable = false,
                border = { text = { top = " Chezmoi " } },
            },
        },
    },
    init = function()
        local shell_out_grp =
            vim.api.nvim_create_augroup("ShellOutputGrp", { clear = true })

        vim.api.nvim_create_autocmd("WinLeave", {
            group = shell_out_grp,
            callback = function(ev)
                if vim.bo[ev.buf].filetype ~= "noice_shell_split" then
                    return
                end

                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(ev.buf) then
                        vim.api.nvim_buf_delete(ev.buf, { force = true })
                    end
                end)
            end,
        })
    end,
}
