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
        { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
        {
            "<leader>gc",
            function() require("config.plugins.git.utils").open_commit_tab() end,
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
