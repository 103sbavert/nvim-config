--- @type LazySpec
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    dependencies = { "neovim/nvim-lspconfig", "config.utils" },
    --- @type PluginConfig
    opts = {
        preset = "modern",
        options = {
            throttle = 500,
            add_messages = {
                display_count = true,
            },
        },
    },
    init = function()
        vim.diagnostic.config({
            virtual_text = false,
            virtual_lines = false,
            signs = {
                text = require("config.utils").lsp_diagnostic_glyphs[vim.g.have_nerd_font],
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
        })
    end,
}
