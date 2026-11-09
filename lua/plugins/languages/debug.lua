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
                "<leader>d",
                function() require("dap").continue() end,
                desc = "[d]ebug",
                mode = { "n" },
            },
        },
        init = function() MasonInstall(dap_list) end,
        config = function()
            local utils = require("plugins.languages.internal.utils")
            local dap = require("dap")

            require("plugins.languages.internal.delve").setup()
            utils.setup_dap_signs()

            -- open dap ui on startup
            dap.listeners.after.event_initialized["open_dap_ui"] = function()
                require("dap-view").open()
            end

            -- map debug-session-only keymaps
            do
                dap.listeners.after.event_initialized["dap_keymaps"] = function()
                    utils.add_dap_keymaps()
                end
                dap.listeners.before.event_terminated["dap_keymaps"] = function()
                    utils.del_dap_keymaps()
                end
                dap.listeners.before.event_exited["dap_keymaps"] = function()
                    utils.del_dap_keymaps()
                end
            end

            -- override keymap description based on the debugger state (Debug vs Continue)
            do
                local set_start_keymap = function()
                    vim.keymap.set("n", "<leader>d", dap.continue, {
                        desc = "[d]ebug",
                    })
                end

                dap.listeners.after.event_initialized["continue_keymap_desc"] = function()
                    pcall(vim.keymap.del, "n", "<leader>d")
                end

                dap.listeners.after.event_terminated["continue_keymap_desc"] =
                    set_start_keymap
                dap.listeners.after.event_exited["continue_keymap_desc"] =
                    set_start_keymap
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
