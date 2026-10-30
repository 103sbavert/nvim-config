local ls_config = nil
local get_ls_conf = function()
    ls_config = ls_config
        or require("plugins.languages.internal.utils").LsConfig

    if not ls_config or vim.tbl_isempty(ls_config) then
        vim.notify("No language servers configured", vim.log.levels.WARN)
        return nil
    end

    return ls_config
end

--- @type LazySpec
return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "config.utils",
            "j-hui/fidget.nvim",
        },
        init = function()
            local configured_ls = vim.tbl_keys(get_ls_conf() or {})
            local managed_ls = { "roslyn_ls" }
            vim.list_extend(configured_ls, managed_ls)

            MasonInstall(configured_ls)
        end,
        config = function()
            require("plugins.languages.internal.autocmds")

            for name, server_conf in pairs(get_ls_conf() or {}) do
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
        lazy = true,
        config = true,
    },
    {
        "brianhuster/live-preview.nvim",
        ft = { "markdown" },
        dependencies = {
            "folke/snacks.nvim",
        },
        lazy = true,
        config = true,
    },
    {
        "GustavEikaas/easy-dotnet.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
        lazy = true,
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
        lazy = true,
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

                local lang_utils = require("plugins.languages.internal.utils")

                return not lang_utils.has_lua_config(root_dir)
            end,
        },
    },
}
