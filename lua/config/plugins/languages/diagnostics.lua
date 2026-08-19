---@type LazySpec
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    dependencies = "neovim/nvim-lspconfig",
    ---@type PluginConfig
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
    init = function()
        vim.diagnostic.config({
            virtual_text = false,
            signs = {
                text = require("config.utils").lsp_diagnostic_glyphs[vim.g.have_nerd_font],
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
        })
    end,
}
