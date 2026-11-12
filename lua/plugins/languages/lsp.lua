local shuck = require("plugins.languages.internal.shuck")
local gopls = require("plugins.languages.internal.gopls")
local lua_ls = require("plugins.languages.internal.lua_ls")
local typst = require("plugins.languages.internal.typst")

--- @type table<string, vim.lsp.Config>
local ls_config = {
    gitlab_ci_ls = {},
    pyright = {},
    phpactor = {},
    vtsls = {},
    shuck = shuck.lsp_config,
    markdown_oxide = {},
    tinymist = typst.lsp_config,
    gopls = gopls.lsp_config,
    lua_ls = lua_ls.lsp_config,
}

--- @type LazySpec
return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "config.utils",
            "j-hui/fidget.nvim",
            "rachartier/tiny-inline-diagnostic.nvim",
        },
        event = "VimEnter",
        init = function()
            local configured_ls = vim.tbl_keys(ls_config)
            local managed_ls = { "roslyn_ls" }
            vim.list_extend(configured_ls, managed_ls)

            MasonInstall(configured_ls)
        end,
        config = function()
            require("plugins.languages.internal.autocmds")

            for name, server_conf in pairs(ls_config) do
                vim.lsp.config(name, server_conf)
                vim.lsp.enable(name)
            end
        end,
    },
    {
        "ymic9963/mdnotes.nvim",
        ft = { "markdown" },
        cmd = {
            "Mdn",
        },
        config = true,
    },
    {
        "brianhuster/live-preview.nvim",
        ft = { "markdown" },
        dependencies = {
            "folke/snacks.nvim",
        },
        config = true,
    },
    {
        "GustavEikaas/easy-dotnet.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
        ft = { "cs", "razor", "msbuild_proj", "solution" },
        init = function()
            vim.filetype.add({
                extension = {
                    csproj = "msbuild_proj",
                    fsproj = "msbuild_proj",
                    vbproj = "msbuild_proj",
                    props = "msbuild_proj",
                    targets = "msbuild_proj",
                    slnx = "solution",
                    nuspec = "xml",
                },
            })
        end,
        config = true,
    },
    {
        "chomosuke/typst-preview.nvim",
        ft = "typst",
        version = "1.*",
        config = true,
    },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                vim.env.VIMRUNTIME,
                vim.fs.joinpath(
                    vim.fn.stdpath("data"),
                    "site/pack/core/opt/lazy.nvim"
                ),
                {
                    path = vim.fs.joinpath(
                        vim.fn.stdpath("data"),
                        "site/pack/core/opt/bamboo.nvim"
                    ),
                    words = { "bamboo" },
                },
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
            enabled = function(root_dir)
                if vim.g.lazy_lua_ls then
                    return true
                end

                return not lua_ls.has_lua_config(root_dir)
            end,
        },
    },
}
