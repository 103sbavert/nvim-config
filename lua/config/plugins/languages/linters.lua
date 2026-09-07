local linters_by_ft = {
    markdown = { "markdownlint-cli2" },
    javascript = { "eslint_d" },
    typescript = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    typescriptreact = { "eslint_d" },
}

--- @type LazySpec
return {
    "mfussenegger/nvim-lint",
    dependencies = { "config.mason" },
    event = { "VeryLazy" },
    init = function()
        local linters = {}
        for _, ft_linters in pairs(linters_by_ft or {}) do
            vim.list_extend(linters, ft_linters)
        end

        require("config.mason").InstallTools(linters)
    end,
    config = function()
        local lint = require("lint")

        lint.linters_by_ft = linters_by_ft

        -- Force markdownlint-cli2 to accept input via stdin instead of reading disk files
        lint.linters["markdownlint-cli2"].args = { "-" }
        lint.linters["markdownlint-cli2"].stdin = true

        local lint_augroup =
            vim.api.nvim_create_augroup("lint", { clear = true })

        vim.api.nvim_create_autocmd(
            { "BufReadPost", "BufWritePost", "InsertLeave" },
            {
                group = lint_augroup,
                callback = function()
                    -- Only run the linter in buffers that you can modify in order to
                    -- avoid superfluous noise, notably within the handy LSP pop-ups that
                    -- describe the hovered symbol using Markdown.
                    if vim.bo.modifiable then
                        lint.try_lint()
                    end
                end,
            }
        )
    end,
}
