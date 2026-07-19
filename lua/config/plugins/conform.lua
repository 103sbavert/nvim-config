return {
    "stevearc/conform.nvim",
    opts = {
        notify_on_error = false,
        default_format_opts = {
            lsp_format = "fallback", -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
        },
        format_after_save = {
            async = true,
            timeout_ms = 500,
        },
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort" },
            go = { "goimports" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            json = { "prettier" },
            yaml = { "prettier" },
            toml = { "taplo" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            zsh = { "shfmt" },
        },
        formatters = {
            stylua = {},
            shfmt = {
                args = { "-i", "4", "-ci" },
            },
            prettier = {
                args = {
                    "--log-level",
                    "error",
                    "--tab-width",
                    "4",
                    "--stdin-filepath",
                    "$FILENAME",
                },
            },
            taplo = {
                args = { "fmt", "--option", "indent_string=    ", "-" },
            },
        },
    },
    config = function(_, opts)
        local conform = require("conform")
        conform.setup(opts)

        local formatters = {
            "shfmt",
            "taplo",
            "prettier",
            "isort",
            "stylua",
            "goimports",
        }
        require("config.mason").InstallTools(formatters)

        vim.api.nvim_create_user_command(
            "Format",
            function(_) conform.format() end,
            { desc = "Format current buffer or visual selection" }
        )

        vim.keymap.set({ "n", "v" }, "<leader>f", "<Cmd>Format<Cr>", { desc = "[f]ormat buffer or visual selection" })
    end,
}
