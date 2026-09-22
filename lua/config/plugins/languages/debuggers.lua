local dap_list = { "delve" }

--- @type LazySpec[]
return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "leoluz/nvim-dap-go",
            "config.mason",
        },
        keys = {
            {
                "<leader>b<space>",
                function() require("dap").toggle_breakpoint() end,
                mode = { "n" },
                desc = "[ ] toggle",
            },
            {
                "<leader>bc",
                function()
                    vim.ui.input(
                        { prompt = "Breakpoint condition: " },
                        function(input)
                            if input then
                                require("dap").set_breakpoint(input)
                            end
                        end
                    )
                end,
                desc = "Add [c]ondition",
                mode = { "n" },
            },
            {
                "<leader>d",
                function() require("dap").continue() end,
                desc = "start [d]ebugging",
                mode = { "n" },
            },
        },
        init = function() require("config.mason").InstallTools(dap_list) end,
        config = function()
            local utils = require("config.plugins.languages.internal.utils")
            local dap = require("dap")

            utils.setup_dap_signs()

            dap.listeners.after.event_initialized["open_dap_ui"] = function()
                require("dapui").open()
            end
            dap.listeners.after.event_initialized["dap_keymaps"] = function()
                utils.setup_dap_overrides()
            end
            dap.listeners.before.event_terminated["dap_keymaps"] = function()
                utils.unset_dap_overrides()
            end
            dap.listeners.before.event_exited["dap_keymaps"] = function()
                utils.unset_dap_overrides()
            end
        end,
    },
    {
        "leoluz/nvim-dap-go",
        ft = { "go" },
        dependencies = { "mfussenegger/nvim-dap" },
        config = function(_, opts)
            local dap = require("dap")
            require("dap-go").setup(opts)

            dap.configurations.go = dap.configurations.go or {}

            for _, conf in ipairs(dap.configurations.go) do
                if conf.processId and vim.is_callable(conf.processId) then
                    conf.processId = function(inner_opts)
                        return require("dap.utils").pick_process(inner_opts)
                    end
                end
            end

            table.insert(
                dap.configurations.go,
                1,
                require("config.plugins.languages.internal.utils").go_debug_auto
            )
        end,
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "config.utils",
            "nvim-neotest/nvim-nio",
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = { clear_on_continue = true },
            },
        },
        keys = {
            {
                "<leader>td",
                function() require("dapui").toggle() end,
                desc = "Toggle [d]ap UI",
                mode = { "n" },
            },
        },
        opts = {
            icons = {
                expanded = "▾",
                collapsed = "▸",
                current_frame = "*",
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
            controls = {
                icons = require("config.utils").debug_button_glyphs[vim.g.have_nerd_font],
            },
        },
    },
}
