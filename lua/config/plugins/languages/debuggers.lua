local dap_list = { "delve" }

--- @type LazySpec[]
return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "theHamsta/nvim-dap-virtual-text",
                config = true,
            },
        },
        keys = {
            {
                "<leader>bb",
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
                "<leader>dd",
                function() require("dap").continue() end,
                desc = "[c]ontinue",
                mode = { "n" },
            },
        },
        init = function() MasonInstall(dap_list) end,
        config = function()
            local utils = require("config.plugins.languages.internal.utils")
            local delve = require("config.plugins.languages.internal.delve")
            local dap = require("dap")

            utils.setup_dap_signs()
            delve.setup()

            dap.listeners.after.event_initialized["open_dap_ui"] = function()
                require("dap-view").open()
            end
            dap.listeners.after.event_initialized["dap_keymaps"] = function()
                utils.add_dap_keymaps()
            end
            dap.listeners.before.event_terminated["dap_keymaps"] = function()
                utils.del_dap_keymaps()
            end
            dap.listeners.before.event_exited["dap_keymaps"] = function()
                utils.del_dap_keymaps()
            end
        end,
    },
    {
        "igorlfs/nvim-dap-view",
        dependencies = {
            "mfussenegger/nvim-dap",
            "config.utils",
        },
        keys = {
            {
                "<leader>td",
                function() require("dap-view").toggle() end,
                desc = "Toggle [d]ap UI",
                mode = { "n" },
            },
        },
        opts = {
            winbar = {
                show = true,
                sections = {
                    "watches",
                    "exceptions",
                    "breakpoints",
                    "repl",
                    "console",
                },
                show_keymap_hints = true,
            },
        },
    },
}
