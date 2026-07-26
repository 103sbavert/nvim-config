return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",
        "leoluz/nvim-dap-go",
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        ---@diagnostic disable-next-line: missing-fields
        dapui.setup({
            -- Set icons to characters that are more likely to work in every terminal.
            --    Feel free to remove or use ones that you like more! :)
            --    Don't feel like these are good choices.
            icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
            ---@diagnostic disable-next-line: missing-fields
            controls = {
                icons = {
                    pause = "⏸",
                    play = "▶",
                    step_into = "⏎",
                    step_over = "⏭",
                    step_out = "⏮",
                    step_back = "b",
                    run_last = "▶▶",
                    terminate = "⏹",
                    disconnect = "⏏",
                },
            },
            position = "right",
        })

        local mason_daps = {
            "delve",
        }

        require("nvim-dap-virtual-text").setup({
            clear_on_continue = true,
        })

        require("mason-nvim-dap").setup({
            ensure_installed = mason_daps,
            automatic_installation = true,
        })

        local breakpoint_grp = create_keymap_group("[B]reakpoints", "gB", { "n" })

        breakpoint_grp("t", dap.toggle_breakpoint, "[t]oggle")
        breakpoint_grp(
            "c",
            function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
            "[c]onditional breakpoint"
        )

        -- Auto-open/close UI
        dap.listeners.before.attach["dapui_config"] = dapui.open
        dap.listeners.before.launch["dapui_config"] = dapui.open
        dap.listeners.after.event_initialized["dapui_config"] = dapui.open
        dap.listeners.before.event_terminated["dapui_config"] = dapui.close
        dap.listeners.before.event_exited["dapui_config"] = dapui.close

        vim.keymap.set("n", "<F5>", dap.continue)
        vim.keymap.set("n", "<F6>", dap.close)
        vim.keymap.set("n", "<F10>", dap.step_over)
        vim.keymap.set("n", "<F11>", dap.step_into)
        vim.keymap.set("n", "<F12>", dap.step_out)

        require("dap-go").setup({
            delve = {

                detached = vim.fn.has("win32") == 0,
            },
        })
    end,
}
