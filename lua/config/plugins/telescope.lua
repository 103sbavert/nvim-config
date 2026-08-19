---@type LazySpec
return {
    main = "telescope",
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-ui-select.nvim",
        "config.utils",
        "folke/which-key.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function() return vim.fn.executable("make") == 1 end,
        },
    },
    opts = {
        defaults = {
            layout_config = {
                horizontal = {
                    preview_width = 0.6,
                },
            },
        },
        extensions = {
            ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
    },
    config = function(plugin, tsp_opts)
        local tsp = require(plugin.main)
        tsp.setup(tsp_opts)

        tsp.load_extension("fzf")
        tsp.load_extension("ui-select")

        local map_search = create_keymap_group("[s]earch", "<leader>s", "n")
        local builtin = require("telescope.builtin")

        -- primary file & buffer navigation
        map_search("f", builtin.find_files, "[f]ind files")
        map_search("r", builtin.oldfiles, "[r]ecent files")
        map_search("b", builtin.buffers, "[b]uffers")
        map_search("g", builtin.git_status, "[g]it status")

        -- text & grep search
        map_search("/", builtin.live_grep, "[/] grep workspace")
        map_search(
            "w",
            builtin.grep_string,
            "search current [w]ord",
            nil,
            { "n", "v" }
        )
        map_search(
            "o",
            function()
                builtin.live_grep({
                    grep_open_files = true,
                    prompt_title = "Live Grep in Open Files",
                })
            end,
            "grep [o]pen files"
        )

        -- system & metadata
        map_search(
            "c",
            function()
                builtin.find_files({
                    cwd = vim.fn.stdpath("config"),
                    follow = true,
                })
            end,
            "[c]onfig files"
        )
        map_search("h", builtin.help_tags, "[h]elp tags")
        map_search("k", builtin.keymaps, "[k]eymaps")
        map_search("m", builtin.commands, "[m]odule commands")
        map_search("d", builtin.diagnostics, "[d]iagnostics")
        map_search(".", builtin.resume, "[.] resume search")
        map_search("?", builtin.builtin, "[?] telescope builtins")

        -- buffer-local search (kept separate for high-frequency access)
        vim.keymap.set(
            "n",
            "<leader>/",
            function()
                builtin.current_buffer_fuzzy_find(
                    require("telescope.themes").get_dropdown({
                        winblend = 10,
                        previewer = false,
                    })
                )
            end,
            { desc = "[/] search in current buffer" }
        )
    end,
}
