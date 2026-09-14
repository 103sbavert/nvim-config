--- @type any
local lazy_dap = nil
--- @type any
local lazy_dap_ui = nil

local get_dap = function()
    lazy_dap = lazy_dap or require("dap")
    return lazy_dap
end

--- @type fun(): any
local get_dapui = function()
    lazy_dap_ui = lazy_dap_ui or require("dapui")
    return lazy_dap_ui
end

--- @return LazyPluginSpec
local function dap_ui_spec()
    return {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "config.utils",
            "nvim-neotest/nvim-nio",
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {
                    clear_on_continue = true,
                },
            },
        },
        keys = {
            {
                "<F6>",
                function() get_dapui().open() end,
                desc = "Open DAP UI",
                mode = { "n", "i", "x", "v" },
            },
            {
                "<S-F6>",
                function() get_dapui().close() end,
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
        },
        config = function(_, opts)
            opts.controls = {
                icons = require("config.utils").debug_button_glyphs[vim.g.have_nerd_font],
            }
            require("dapui").setup(opts)
        end,
    }
end

--- @type LazySpec
return {
    "mfussenegger/nvim-dap",
    dependencies = {
        { "leoluz/nvim-dap-go", ft = { "go" }, config = true },
        dap_ui_spec(),
        "config.mason",
    },
    keys = {
        {
            "<leader>b<CR>",
            function() get_dap().toggle_breakpoint() end,
            mode = { "n" },
            desc = "[t]oggle",
        },
        {
            "<leader>bc",
            function()
                vim.ui.input(
                    { prompt = "Breakpoint condition: " },
                    function(input)
                        if input then
                            get_dap().set_breakpoint(input)
                        end
                    end
                )
            end,
            desc = "Add [c]ondition",
            mode = { "n" },
        },
        {
            "<F5>",
            function() get_dap().continue() end,
            desc = "Start Debugger",
            mode = { "n", "i", "x", "v" },
        },
        {
            "<S-F5>",
            function() get_dap().terminate() end,
            desc = "Terminate Debugger",
            mode = { "n", "i", "x", "v" },
        },
        {
            "<F10>",
            function() get_dap().step_over() end,
            desc = "Step Over",
            mode = { "n", "i", "x", "v" },
        },
        {
            "<F11>",
            function() get_dap().step_into() end,
            desc = "Step Into",
            mode = { "n", "i", "x", "v" },
        },
        {
            "<S-F11>",
            function() get_dap().step_out() end,
            desc = "Step Out",
            mode = { "n", "i", "x", "v" },
        },
    },
    config = function()
        local mason_daps = {
            "delve",
        }

        require("config.mason").InstallTools(mason_daps)

        -- Auto-open/close UI
        get_dap().listeners.before.attach["dapui_config"] = function()
            get_dapui().open()
        end

        get_dap().listeners.before.launch["dapui_config"] = function()
            get_dapui().open()
        end

        get_dap().listeners.after.event_initialized["dapui_config"] = function()
            get_dapui().open()
        end

        get_dap().listeners.after.event_terminated["dapui_config"] = function()
            get_dapui().close()
        end

        get_dap().listeners.after.event_exited["dapui_config"] = function()
            get_dapui().close()
        end

        get_dap().listeners.after.event_disconnect["dapui_config"] = function()
            get_dapui().close()
        end
    end,
}
