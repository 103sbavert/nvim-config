local conform = require("conform")

local formatters = {
    "shfmt",
    "taplo",
    "prettier",
    "isort",
}

require("mason-tool-installer").setup({ ensure_installed = formatters, auto_update = true })

conform.setup({
    notify_on_error = false,
    default_format_opts = {
        lsp_format = "fallback", -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    format_after_save = {
        async = true,
        timeout_ms = 500,
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
        lua = { "stylua" }, -- installed in init.lua with other LSPs
        python = { "isort" },
        go = { "gofmt" },
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
})

vim.api.nvim_create_user_command(
    "Format",
    function(_) conform.format({ async = true }) end,
    { desc = "Format current buffer or visual selection" }
)

vim.keymap.set({ "n", "v" }, "<leader>f", "<Cmd>Format<Cr>", { desc = "[f]ormat buffer or visual selection" })
