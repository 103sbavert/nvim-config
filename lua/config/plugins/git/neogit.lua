--- @type LazySpec
return {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
        "sindrets/diffview.nvim",
        "m00qek/baleia.nvim",
        "folke/snacks.nvim",
    },
    cmd = "Neogit",
    keys = {
        { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
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
