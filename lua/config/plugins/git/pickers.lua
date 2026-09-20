--- @type LazySpec
return {
    "esmuellert/codediff.nvim",
    dependencies = {
        "NeogitOrg/neogit",
        "folke/snacks.nvim",
        "config.utils",
    },
    lazy = true,
    keys = function()
        local utils = require("config.plugins.git.utils")
        return {
            --- Git picker integration
            {
                "<leader>gd",
                function()
                    local callback = function(hash, file)
                        local args = { hash }
                        if file and file ~= "" then
                            table.insert(args, file)
                        end

                        vim.cmd({
                            cmd = "CodeDiff",
                            args = args,
                        })
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
                function()
                    Snacks.picker.git_status({
                        layout = utils.get_layout(),
                    })
                end,
                desc = "s[t]atus",
            },
            {
                "<leader>gD",
                function() vim.cmd("CodeDiff --cached HEAD") end,
                desc = "[D]iff staged",
            },
        }
    end,
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
