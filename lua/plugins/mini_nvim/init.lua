--- @type LazySpec
return {
    "nvim-mini/mini.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
    },
    config = function()
        require("plugins.mini_nvim.around_in")
        require("plugins.mini_nvim.statusline")

        require("mini.surround").setup({
            mappings = {
                add = "s", -- conflicts with builtin substitute; intended
                find = "s/",
                find_left = "s?",
                update_n_lines = "sn", -- no default mapping; custom
            },
        })

        require("mini.comment").setup()

        if vim.g.have_nerd_font then
            require("mini.icons").setup()
        end
    end,
}
