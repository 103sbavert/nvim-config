---@type LazySpec
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    dependencies = "neovim/nvim-lspconfig",
    ---@type PluginConfig
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
        vim.keymap.set(
            "n",
            "<leader>q",
            vim.diagnostic.setloclist,
            { desc = "Open diagnostic [q]uickfix list" }
        )

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
