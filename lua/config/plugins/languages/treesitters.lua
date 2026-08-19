---@type LazySpec
return {
    main = "nvim-treesitter",
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "config.mason" },
    build = ":TSUpdate",
    config = function(plugin, treesitter_opts)
        local treesitter = require(plugin.main)
        treesitter.setup(treesitter_opts)

        require("config.mason").InstallTools({ "tree-sitter-cli" })

        -- Ensure basic parsers are installed
        local parsers = {
            "bash",
            "c",
            "zsh",
            "go",
            "diff",
            "yaml",
            "toml",
            "json",
            "html",
            "lua",
            "luadoc",
            "markdown",
            "markdown_inline",
            "query",
            "vim",
            "vimdoc",
        }

        treesitter.install(parsers)

        local function treesitter_try_attach(buf, language)
            if not vim.treesitter.language.add(language) then
                return
            end

            vim.treesitter.start(buf, language)

            local has_indent_query = vim.treesitter.query.get(
                language,
                "indents"
            ) ~= nil

            if has_indent_query then
                vim.bo.indentexpr =
                    "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end

        local available_parsers = treesitter.get_available()
        local installed_parsers = treesitter.get_installed("parsers")

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local buf, filetype = args.buf, args.match

                local language = vim.treesitter.language.get_lang(filetype)
                if not language then
                    return
                end

                if vim.tbl_contains(installed_parsers, language) then
                    treesitter_try_attach(buf, language)
                elseif vim.tbl_contains(available_parsers, language) then
                    treesitter
                        .install(language)
                        :await(
                            function() treesitter_try_attach(buf, language) end
                        )
                else
                    treesitter_try_attach(buf, language)
                end
            end,
        })
    end,
}
