--- @type LazySpec
return {
    "NeogitOrg/neogit",
    main = "neogit",
    lazy = true,
    dependencies = {
        "esmuellert/codediff.nvim",
        "m00qek/baleia.nvim",
        "folke/snacks.nvim",
    },
    cmd = "Neogit",
    keys = {
        { "<leader>gn", "<cmd>Neogit<cr>", desc = "[n]eogit" },
        {
            "<leader>gc",
            function() require("plugins.git.utils").open_commit_tab() end,
            desc = "[c]ommit staged",
        },
    },
    opts = {
        disable_insert_on_commit = false,
        graph_style = "kitty",
        process_spinner = true,
        integrations = {
            snacks = true,
        },
    },
}
