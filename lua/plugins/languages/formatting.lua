local getutils = function() return require("plugins.languages.internal.utils") end

--- @type LazySpec
return {
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Format" },
    keys = {
        {
            "<leader>f",
            "<CMD>Format<CR>",
            desc = "[f]ormat buffer",
            mode = "n",
        },
    },
    init = function()
        local mason_formatters = {
            "shfmt",
            "prettier",
            "isort",
            "goimports",
            "gofumpt",
            "stylua",
        }

        MasonInstall(mason_formatters)

        _G.format_expr_fn = function()
            local utils = require("plugins.languages.internal.utils")
            local bufnr = vim.api.nvim_get_current_buf()
            local range = nil

            if vim.v.lnum > 0 and vim.v.count > 0 then
                range = {
                    start_line = vim.v.lnum,
                    end_line = vim.v.lnum + vim.v.count - 1,
                }
            end
            return utils.FormatBuffer(bufnr, false, range)
        end

        vim.o.formatexpr = "v:lua.format_expr_fn()"
    end,
    config = function()
        local null_ls = require("null-ls")
        local b = null_ls.builtins
        local utils = getutils()

        local formatters = {
            b.formatting.prettier.with({
                extra_args = function(ctx)
                    return {
                        "--tab-width",
                        tostring(utils.get_indent(ctx.bufnr)),
                    }
                end,
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
            }),
            b.formatting.shfmt.with({
                extra_args = function(ctx)
                    return {
                        "-i",
                        tostring(utils.get_indent(ctx.bufnr)),
                        "-ci",
                    }
                end,
            }),
            b.formatting.isort,
            b.formatting.stylua,
            b.formatting.goimports,
            b.formatting.gofumpt,
        }

        null_ls.setup({
            sources = formatters,
        })

        vim.api.nvim_create_user_command(
            "Format",
            function() utils.FormatBuffer(vim.api.nvim_get_current_buf(), true) end,
            {
                desc = "Format current buffer using none-ls",
            }
        )
    end,
}
