--- @type LazySpec
return {
    "esmuellert/codediff.nvim",
    dependencies = {
        "NeogitOrg/neogit",
        "folke/snacks.nvim",
        "config.utils",
    },
    lazy = true,
    keys = {
        --- Git picker integration
        {
            "<leader>gd",
            function()
                local utils = require("config.plugins.git.utils")

                local callback = function(hash, file)
                    local cmd_parts = table.concat({
                        "CodeDiff",
                        hash,
                        file,
                    }, " ") -- split by space

                    vim.cmd(cmd_parts)
                end
                local file_name = require("config.utils").get_current_file()
                utils.git_log_picker(file_name, callback)
            end,
            desc = "[d]iff against...",
        },
        {
            "<leader>go",
            function() require("config.plugins.git.utils").git_log_picker() end,
            desc = "l[o]g",
        },
        {
            "<leader>gt",
            function() Snacks.picker.git_status() end,
            desc = "s[t]atus",
        },
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
