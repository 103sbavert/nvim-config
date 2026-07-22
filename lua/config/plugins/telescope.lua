return {
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
    config = function()
        local tsp = require("telescope")

        tsp.setup({
            extensions = {
                ["ui-select"] = { require("telescope.themes").get_dropdown() },
            },
        })

        tsp.load_extension("fzf")
        tsp.load_extension("ui-select")

        local map_search = create_keymap_group("[ ] search", "<leader><leader>", "n")
        local builtin = require("telescope.builtin")

        map_search("h", builtin.help_tags, "[h]elp pages")
        map_search("k", builtin.keymaps, "nvim [k]eymaps")
        map_search("w", builtin.find_files, "[w]orkspace files")
        map_search("/", builtin.builtin, "/ select telescope")
        map_search("g", builtin.live_grep, "[g]rep workspace")
        map_search("d", builtin.diagnostics, "[d]iagnostics")
        map_search(".", builtin.resume, ". resume search")
        map_search("r", builtin.oldfiles, "[r]ecent files")
        map_search("c", builtin.commands, "[c]ommands")
        map_search("w", builtin.grep_string, "current [w]ORD", nil, { "n", "v" })

        map_search(
            "o",
            function()
                builtin.live_grep({
                    grep_open_files = true,
                    prompt_title = "grep in open files",
                })
            end,
            "grep [o]pen files"
        )

        map_search(
            "n",
            function() builtin.find_files({ cwd = vim.fn.stdpath("config"), follow = true }) end,
            "[n]eovim files"
        )

        vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "find existing [b]uffers" })

        vim.keymap.set(
            "n",
            "<leader>/",
            function()
                builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                    wnblend = 10,
                    previewer = false,
                }))
            end,
            { desc = "[/] fuzzy search current buffer" }
        )
    end,
}
