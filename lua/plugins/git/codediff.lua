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
            "<leader>gD",
            function() vim.cmd("CodeDiff --cached HEAD") end,
            desc = "[D]iff staged",
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
