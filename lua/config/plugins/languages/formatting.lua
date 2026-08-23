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
            cs = { "jb" },
            markdown = { "prettier" },
        },
        formatters = {
            stylua = {},
            shfmt = {
                args = function(_, ctx)
                    return { "-i", tostring(get_indent(ctx.buf)), "-ci" }
                end,
            },
            jb = function()
                local user_config_home = vim.env.XDG_CONFIG_HOME

                if not user_config_home then
                    user_config_home = vim.fs.joinpath(vim.env.HOME, ".config")
                end

                if not user_config_home then
                    vim.notify(
                        "User config home could not be determined",
                        vim.log.levels.WARN,
                        { title = "Chezmoi" }
                    )
                    return
                end

                local jb_global_config = vim.fs.joinpath(
                    user_config_home,
                    "JetBrains/Shared/vAny/GlobalSettingsStorage.DotSettings"
                )

                return {
                    args = {
                        "cleanupcode",
                        "--include",
                        "$FILENAME",
                        "--profile",
                        jb_global_config,
                    },
                }
            end,
            prettier = {
                args = function(_, ctx)
                    return {
                        "--log-level",
                        "error",
                        "--tab-width",
                        tostring(get_indent(ctx.buf)),
                        "--stdin-filepath",
                        "$FILENAME",
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
            "prettier",
            "isort",
            "stylua",
            "goimports",
        }

        require("config.mason").InstallTools(mason_formatters)

        vim.api.nvim_create_user_command(
            "Format",
            function(_) conform.format({ async = true }) end,
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
