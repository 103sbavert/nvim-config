---@type LazySpec
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    dependencies = "neovim/nvim-lspconfig",
    opts = {
        options = {
            multilines = {
                enabled = true,
                always_show = true,
            },
            show_source = true,
        },
    },
}
