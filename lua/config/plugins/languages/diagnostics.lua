---@type LazySpec
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    dependencies = "neovim/nvim-lspconfig",
    opts = {
        preset = "modern",
        options = {
            show_source = {
                enabled = true,
                if_many = true,
            },
            show_code = true,
            use_icons_from_diagnostic = true,
            throttle = 500,
            add_messages = {
                display_count = true,
            },
            multilines = {
                enabled = true,
                always_show = false,
                trim_whitespaces = true,
            },
            show_related = {
                enabled = true,
                max_count = 3,
            },
        },
    },
}
