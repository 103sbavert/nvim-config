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
                "<F5>",
                function() require("dap").continue() end,
                desc = "Start Debugger",
                mode = { "n", "i", "x", "v" },
            },
            {
                "<S-F5>",
                function() require("dap").terminate() end,
                desc = "Terminate Debugger",
                mode = { "n", "i", "x", "v" },
            },
            {
                "<F10>",
                function() require("dap").step_over() end,
                desc = "Step Over",
                mode = { "n", "i", "x", "v" },
            },
            {
                "<F11>",
                function() require("dap").step_into() end,
                desc = "Step Into",
                mode = { "n", "i", "x", "v" },
            },
            {
                "<S-F11>",
                function() require("dap").step_out() end,
                desc = "Step Out",
                mode = { "n", "i", "x", "v" },
            },
        },
        init = function() require("config.mason").InstallTools(dap_list) end,
        config = function()
            require("config.plugins.languages.internal.utils").setup_dap_signs()
            local dap = require("dap")

            dap.listeners.before.event_initialized["dapui_config"] = function()
                require("dapui").open()
            end
        end,
    },
    {
        "leoluz/nvim-dap-go",
        ft = { "go" },
        dependencies = { "mfussenegger/nvim-dap" },
        config = function(_, opts)
            local dap_go = require("dap-go")
            dap_go.setup(opts)

            local auto_main_config = {
                type = "go",
                name = "Debug Main (Auto)",
                request = "launch",
                program = function()
                    local cwd = vim.fn.getcwd(0, 0)
                    local main_files =
                        require("config.utils").find_files_by_name(
                            cwd,
                            "main.go",
                            6
                        )

                    if #main_files == 1 then
                        return vim.fs.dirname(main_files[1])
                    end

                    -- NOTE: DAP has custom logic for handling so we can't use
                    -- the global wrappers for coroutine here
                    return coroutine.create(function(dap_co)
                        if #main_files == 0 then
                            vim.ui.input({
                                prompt = "No main.go found. Specify path: ",
                                default = cwd .. "/",
                                completion = "file",
                            }, function(input)
                                if input and input ~= "" then
                                    if vim.fn.isdirectory(input) == 1 then
                                        coroutine.resume(dap_co, input)
                                    else
                                        coroutine.resume(
                                            dap_co,
                                            vim.fs.dirname(input)
                                        )
                                    end
                                else
                                    coroutine.resume(dap_co, nil)
                                end
                            end)
                        else
                            vim.ui.select(main_files, {
                                prompt = "Select main.go:",
                                format_item = function(item)
                                    return vim.fs.normalize(item):sub(#cwd + 2)
                                end,
                            }, function(choice)
                                if choice then
                                    coroutine.resume(
                                        dap_co,
                                        vim.fs.dirname(choice)
                                    )
                                else
                                    coroutine.resume(dap_co, nil)
                                end
                            end)
                        end
                    end)
                end,
            }

            local dap = require("dap")
            table.insert(dap.configurations.go, 1, auto_main_config)
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
                "<F6>",
                function() require("dapui").open() end,
                desc = "Open DAP UI",
                mode = { "n", "i", "x", "v" },
            },
            {
                "<S-F6>",
                function() require("dapui").close() end,
                desc = "Close DAP UI",
                mode = { "n", "i", "x", "v" },
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
