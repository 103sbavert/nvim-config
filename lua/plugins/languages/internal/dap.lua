local M = {}

local get_dap = function() return require("dap") end

function M.setup_dap_signs()
    local b = vim.g.have_nerd_font

    --- @type table<string, vim.fn.sign_define.dict>
    local signs = {
        ["DapBreakpoint"] = {
            text = b and "" or "●",
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "",
        },
        ["DapBreakpointCondition"] = {
            text = b and "" or "◆",
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "",
        },
        ["DapBreakpointRejected"] = {
            text = b and "󱥸" or "◌",
            texthl = "DapBreakpointRejected",
            linehl = "",
            numhl = "",
        },
        ["DapLogPoint"] = {
            text = b and "󰝶" or "✎",
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "",
        },
        ["DapStopped"] = {
            text = b and "󰜴" or "➔",
            texthl = "DapStopped",
            linehl = "DapStoppedLine",
            numhl = "DapStoppedLine",
        },
    }

    for name, opts in pairs(signs) do
        pcall(vim.fn.sign_undefine, name)
        vim.fn.sign_define(name, opts)
    end
end

local debug_overrides = {
    ["n"] = {
        ["<leader>dd"] = {
            rhs = function() get_dap().continue() end,
            opts = { desc = "Continue" },
        },
        ["<leader>dx"] = {
            rhs = function() get_dap().terminate() end,
            opts = { desc = "E[x]it" },
        },
        ["<leader>di"] = {
            rhs = function() get_dap().step_into() end,
            opts = { desc = "Step [i]nto" },
        },
        ["<leader>do"] = {
            rhs = function() get_dap().step_out() end,
            opts = { desc = "Step [o]ut" },
        },
        ["<CR>"] = {
            rhs = function() get_dap().step_over() end,
            opts = { desc = "Step over" },
        },
    },
}

function M.add_dap_keymaps()
    for mode, mappings in pairs(debug_overrides()) do
        for lhs, map in pairs(mappings) do
            vim.keymap.set(mode, lhs, map.rhs, map.opts)
        end
    end
end

function M.del_dap_keymaps()
    for mode, mappings in pairs(debug_overrides()) do
        for lhs, _ in pairs(mappings) do
            pcall(vim.keymap.del, mode, lhs)
        end
    end
end

return M
