--- @type LazySpec
return {
    "esmuellert/codediff.nvim",
    dependencies = {
        "folke/snacks.nvim",
    },
    keys = {
        {
            "<leader>gD",
            function() vim.cmd("CodeDiff --cached HEAD") end,
            desc = "[D]iff staged",
        },
        {
            "<leader>gd",
            function()
                local utils = require("config.plugins.git.utils")

                local callback = function(hash)
                    vim.cmd("CodeDiff file " .. hash)
                end

                utils.open_commit_picker(callback)
            end,
            desc = "[d]iff against...",
        },
        {
            "<leader>go",
            function() Snacks.picker.git_log() end,
            desc = "l[o]g",
        },
        {
            "<leader>gt",
            function() Snacks.picker.git_status() end,
            desc = "s[t]atus",
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
    },
}
