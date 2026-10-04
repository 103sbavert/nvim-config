local small_plugins = {
    { "windwp/nvim-autopairs", config = true },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = true,
    },
    {
        "NMAC427/guess-indent.nvim",
        opts = {
            auto_cmd = true,
            --- @type vim.bo
            on_tab_options = {
                expandtab = true,
                softtabstop = -1,
            },
            --- @type vim.bo
            on_space_options = {
                expandtab = true,
                tabstop = "detected",
                softtabstop = "detected",
                shiftwidth = "detected",
            },
        },
    },
    {
        "sphamba/smear-cursor.nvim",
        opts = {
            stiffness = 0.8,
            trailing_stiffness = 0.6,
            stiffness_insert_mode = 0.7,
            trailing_stiffness_insert_mode = 0.7,
            damping = 0.95,
            damping_insert_mode = 0.95,
            distance_stop_animating = 0.5,
            matrix_pixel_threshold = 0.5,
            smear_between_neighbor_lines = false,
        },
        config = true,
    },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = true,
    },
    {
        "j-hui/fidget.nvim",
        lazy = true,
        config = function()
            require("fidget").setup({
                progress = {
                    ignore_done_already = true,
                    ignore_empty_message = true,
                    display = {
                        render_limit = 3,
                        done_ttl = 1,
                    },
                },
            })
        end,
    },
}

local pseudo_plugins = {
    {
        name = "config.su",
        main = "config.su",
        dir = vim.fn.stdpath("config"),
        dependencies = { "mini.nvim" },
        config = true,
    },
    {
        name = "config.utils",
        main = "config.utils",
        dir = vim.fn.stdpath("config"),
        lazy = true,
        dependencies = "j-hui/fidget.nvim",
    },
}

require("lazy").setup({
    --- @type LazySpec[]
    spec = {
        { import = "plugins" },
        pseudo_plugins,
        small_plugins,
    },
    defaults = { lazy = false },
})
