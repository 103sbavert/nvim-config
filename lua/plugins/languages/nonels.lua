--- @type LazySpec
return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvimtools/none-ls-extras.nvim",
    },
    event = { "BufReadPost", "BufNewFile" },

    init = function()
        local mason_tools = {
            "shfmt",
            "prettier",
            "eslint_d",
            "markdownlint-cli2",
            "isort",
            "goimports",
            "gofumpt",
            "stylua",
            "golangci-lint",
            "gitlint",
        }

        MasonInstall(mason_tools)
    end,

    config = function()
        local null_ls = require("null-ls")
        local b = null_ls.builtins
        local utils = require("plugins.languages.internal.utils")

        local eslint_diagnostics = require("none-ls.diagnostics.eslint_d")

        local h = require("null-ls.helpers")
        local FORMATTING = require("null-ls.methods").internal.FORMATTING

        local shuck_format = h.make_builtin({
            name = "shuck_format",
            meta = {
                url = "https://github.com/ewhauser/shuck",
                description = "Shell formatter with per-buffer indent from utils.get_indent.",
            },
            method = FORMATTING,
            filetypes = utils.shuck_filetypes,
            generator_opts = {
                command = "shuck",
                args = utils.shuck_format_args,
                to_stdin = true,
            },
            factory = h.formatter_factory,
        })

        local sources = {
            b.formatting.prettier.with({
                filetypes = {
                    "javascript",
                    "typescript",
                    "javascriptreact",
                    "typescriptreact",
                    "json",
                    "jsonc",
                    "css",
                    "graphql",
                    "markdown",
                    "yaml",
                },
                extra_args = function(ctx)
                    return {
                        "--tab-width",
                        tostring(utils.get_indent(ctx.bufnr)),
                    }
                end,
            }),

            b.diagnostics.golangci_lint.with({
                extra_args = {
                    "--enable=nakedret,nonamedreturns",
                },
            }),

            -- b.diagnostics.gitlint,
            b.diagnostics.gitlint.with({
                extra_args = {
                    "--ignore",
                    "body-max-line-length,body-is-missing",
                },
            }),

            b.formatting.isort,
            b.formatting.stylua,
            b.formatting.goimports,
            b.formatting.gofumpt,
            b.diagnostics.markdownlint_cli2,

            eslint_diagnostics,
            shuck_format,
        }

        null_ls.setup({
            sources = sources,
        })
    end,
}
