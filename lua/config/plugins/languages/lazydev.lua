---@type LazySpec
return {
    "folke/lazydev.nvim",
    ft = "lua",
    ---@type lazydev.Config
    opts = {
        library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            {
                path = vim.fs.joinpath(
                    vim.fn.stdpath("data"),
                    "site/pack/core/opt"
                ),
                words = { "vim.pack" },
            },
            {
                path = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
            },
        },
        enabled = function(root_dir)
            local luarc = vim.fs.joinpath(root_dir, ".luarc.json")
            return not vim.uv.fs_stat(luarc)
        end,
    },
}
