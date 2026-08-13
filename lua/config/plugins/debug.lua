---@type LazySpec
return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",
        "leoluz/nvim-dap-go",
        "folke/which-key.nvim",
    },
    config = function()
        local mason_daps = {
            "delve",
        }

        require("mason-nvim-dap").setup({
            ensure_installed = mason_daps,
            automatic_installation = true,
        })

        local dap = require("dap")
        local dapui = require("dapui")
        require("dap-go").setup()

        ---@diagnostic disable-next-line: missing-fields
        dapui.setup({
            icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
            ---@diagnostic disable-next-line: missing-fields
            controls = {
                icons = require("config.utils").debug_button_glyphs[vim.g.have_nerd_font],
            },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "stacks", size = 0.25 },
                        { id = "watches", size = 0.25 },
                    },
                    size = 36,
                    position = "right",
                },
                {
                    elements = { "console", "repl" },
                    size = 14,
                    position = "bottom",
                },
            },
        })

        -- Auto-open/close UI
        dap.listeners.before.attach["dapui_config"] = dapui.open
        dap.listeners.before.launch["dapui_config"] = dapui.open
        dap.listeners.after.event_initialized["dapui_config"] = dapui.open

        require("nvim-dap-virtual-text").setup({
            clear_on_continue = true,
        })

        local breakpoint_grp = create_keymap_group("[b]reakpoints", "<leader>b", { "n" })
        local function prompt_breakpoint_expr() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end

        breakpoint_grp("<CR>", dap.toggle_breakpoint, "[t]oggle", { nowait = false })
        breakpoint_grp("e", prompt_breakpoint_expr, "conditional [e]xpression", { nowait = false })

        vim.keymap.set("n", "<F5>", dap.continue)
        vim.keymap.set("n", "<S-F5>", dap.terminate)

        vim.keymap.set("n", "<F6>", dapui.open)
        vim.keymap.set("n", "<S-F6>", dapui.close)

        vim.keymap.set("n", "<F10>", dap.step_over)
        vim.keymap.set("n", "<F11>", dap.step_into)
        vim.keymap.set("n", "<S-F11>", dap.step_out)
    end,
}
