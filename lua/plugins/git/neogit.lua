--- @type LazySpec
return {
    "NeogitOrg/neogit",
    main = "neogit",
    lazy = true,
    dependencies = {
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
    --- @module "neogit"
    --- @type NeogitConfig
    opts = {
        disable_insert_on_commit = true,
        graph_style = "kitty",
        remember_settings = false,
        process_spinner = true,
        integrations = {
            snacks = true,
        },
    },
}
