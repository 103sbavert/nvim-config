---@type LazySpec
return {
    "folke/lazydev.nvim",
    ft = "lua",
    ---@type lazydev.Config
    opts = {
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            { path = vim.fn.stdpath("data") .. "/site/pack/core/opt" },
        },
    },
}
