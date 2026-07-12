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
        require("telescope").setup({
            extensions = {
                ["ui-select"] = { require("telescope.themes").get_dropdown() },
            },
        })

        require("telescope").load_extension("fzf")
        require("telescope").load_extension("ui-select")

        local map_search = create_keymap_group("[s]earch", "<leader>s", "n")
        local builtin = require("telescope.builtin")

        map_search("h", builtin.help_tags, "[h]elp")
        map_search("k", builtin.keymaps, "[k]eymaps")
        map_search("f", builtin.find_files, "[f]iles")
        map_search("s", builtin.builtin, "[s]elect Telescope")
        map_search("g", builtin.live_grep, "[g]rep")
        map_search("d", builtin.diagnostics, "[d]iagnostics")
        map_search("r", builtin.resume, "[r]esume")
        map_search(".", builtin.oldfiles, "Recent Files ('.' for repeat)")
        map_search("c", builtin.commands, "[c]ommands")
        map_search("w", builtin.grep_string, "current [W]ord", nil, { "n", "v" })

        map_search(
            "/",
            function()
                builtin.live_grep({
                    grep_open_files = true,
                    prompt_title = "Live Grep in Open Files",
                })
            end,
            "[/] Open Files"
        )

        map_search(
            "n",
            function() builtin.find_files({ cwd = vim.fn.stdpath("config"), follow = true }) end,
            "[n]eovim files"
        )

        vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

        vim.keymap.set(
            "n",
            "<leader>/",
            function()
                builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                    winblend = 10,
                    previewer = false,
                }))
            end,
            { desc = "[/] Fuzzily search in current buffer" }
        )
    end,
}
