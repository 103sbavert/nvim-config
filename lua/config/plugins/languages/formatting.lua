local getutils = function()
    return require("config.plugins.languages.internal.utils")
end

-- prettierd config cache path
-- NOTE: prettierd does not accept config as cmdline args, using this is the
-- best option we have
local prettierd_config_cache = {}

--- @param indent integer
--- @return string path Absolute path to a prettierd config file requesting `indent` as tabWidth.
local function get_prettierd_config_path(indent)
    local cached = prettierd_config_cache[indent]
    if cached then
        return cached
    end

    local path = vim.fs.joinpath(
        vim.fn.stdpath("cache"),
        string.format("prettierd-tabwidth-%d.json", indent)
    )

    if not vim.uv.fs_stat(path) then
        vim.fn.writefile({ vim.fn.json_encode({ tabWidth = indent }) }, path)
    end

    prettierd_config_cache[indent] = path
    return path
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
        format_on_save = {
            async = false,
            timeout_ms = 500,
        },
        formatters_by_ft = {
            -- LS formatters
            lua = { lsp_format = "prefer" }, -- uses stylua as an LS, not lua_ls
            go = { lsp_format = "prefer" },
            -- Custom/CLI formatters
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
            python = { "isort" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            zsh = { "shfmt" },
        },
        formatters = {
            shfmt = {
                args = function(_, ctx)
                    return {
                        "-i",
                        tostring(getutils().get_indent(ctx.buf)),
                        "-ci",
                    }
                end,
            },
            prettierd = {
                env = function(_, ctx)
                    return {
                        PRETTIERD_DEFAULT_CONFIG = get_prettierd_config_path(
                            getutils().get_indent(ctx.buf)
                        ),
                    }
                end,
            },
            taplo = {
                args = function(_, ctx)
                    local indent_string =
                        string.rep(" ", getutils().get_indent(ctx.buf))
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
            "<leader>f",
            function() conform.format({ async = true }) end,
            { desc = "[f]ormat" }
        )

        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
}
