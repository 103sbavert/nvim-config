--- dk (diffkey) returns the prefixxed string for the suffix `k` to be used as
--- a keybind
--- @param k string last key press
--- @return string final generated keymapping
local function dk(k) return "<leader>gd" .. k end

--- @type LazySpec
return {
    "esmuellert/codediff.nvim",
    dependencies = {
        "NeogitOrg/neogit",
        "folke/snacks.nvim",
        "config.utils",
    },
    keys = {
        {
            dk("s"),
            function() vim.cmd("CodeDiff --cached") end,
            desc = "[s]taged",
        },
        {
            dk("w"),
            function() vim.cmd("CodeDiff") end,
            desc = "[w]orktree",
        },
    },
    opts = {
        diff = {
            layout = "side-by-side",
            cycle_next_hunk = true,
            cycle_next_file = true,
            jump_to_first_change = true,
        },
        explorer = {
            position = "left",
            width = 40,
            auto_refresh = true,
        },
        keymaps = {
            view = {
                toggle_stage = false,
            },
        },
    },
}
