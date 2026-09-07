--- Returns effective indent size for bufnr: buffer-local shiftwidth (or tabstop
--- when shiftwidth=0), cascading to global, with 4 as final safety fallback.
--- @param bufnr integer
--- @return integer
local function get_indent(bufnr)
    local sw = vim.bo[bufnr].shiftwidth
    if sw ~= 0 then
        return sw
    end
    -- shiftwidth=0 means "use tabstop"
    local ts = vim.bo[bufnr].tabstop
    if ts ~= 0 then
        return ts
    end
    return 4
end

--- @type LazySpec
return {
    "stevearc/conform.nvim",
    main = "conform",
    --- @type conform.setupOpts
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
            python = { "isort" },
            lua = { lsp_format = "prefer" }, -- uses stylua as an LS, not lua_ls
            go = { lsp_format = "prefer" },
            javascript = { "prettierd" },
            typescript = { "prettierd" },
            javascriptreact = { "prettierd" },
            typescriptreact = { "prettierd" },
            json = { "prettierd" },
            jsonc = { "prettierd" },
            css = { "prettierd" },
            graphql = { "prettierd" },
            markdown = { "prettierd" },
            yaml = { "prettierd" },
            toml = { "taplo" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            zsh = { "shfmt" },
        },
        formatters = {
            shfmt = {
                args = function(_, ctx)
                    return { "-i", tostring(get_indent(ctx.buf)), "-ci" }
                end,
            },
            prettierd = {
                env = function(_, ctx)
                    return {
                        PRETTIERD_DEFAULT_CONFIG = vim.fn.json_encode({
                            tabWidth = get_indent(ctx.buf),
                        }),
                    }
                end,
            },
            taplo = {
                args = function(_, ctx)
                    local indent_string = string.rep(" ", get_indent(ctx.buf))
                    return {
                        "fmt",
                        "--option",
                        "indent_string=" .. indent_string,
                        "-",
                    }
                end,
            },
        },
    },
    config = function(plugin, opts)
        --- @module "conform"
        local conform = require(plugin.main)
        conform.setup(opts)

        local mason_formatters = {
            "shfmt",
            "taplo",
            "prettierd",
            "isort",
        }

        require("config.mason").InstallTools(mason_formatters)

        vim.api.nvim_create_user_command(
            "Format",
            function() conform.format({ async = true }) end,
            { desc = "Format current buffer or visual selection" }
        )

        vim.keymap.set(
            { "n", "v" },
            "<leader>f", -- in normal mode, reformat the entire buffer
            function() conform.format({ async = true }) end,
            { desc = "[F]ormat" }
        )

        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
}
