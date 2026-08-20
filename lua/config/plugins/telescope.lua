---@type LazySpec
return {
    main = "telescope",
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope-ui-select.nvim",
        "config.utils",
        "folke/which-key.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function() return vim.fn.executable("make") == 1 end,
        },
    },
    keys = {
        -- File search
        {
            "<leader>w",
            "<cmd>Telescope find_files<cr>",
            desc = "find [w]orkspace files",
        },
        -- Recent buffers
        {
            "<leader><leader>",
            "<cmd>Telescope buffers<cr>",
            desc = "find recent files",
        },
        -- Text search
        {
            "<leader>?",
            "<cmd>Telescope live_grep<cr>",
            desc = "[?] grep workspace",
        },
        {
            "<leader>/",
            function()
                require("telescope.builtin").current_buffer_fuzzy_find(
                    require("telescope.themes").get_dropdown({
                        winblend = 10,
                        previewer = false,
                    })
                )
            end,
            desc = "[/] grep buffer",
        },
        -- LSP Jump Bindings
        {
            "gd",
            "<cmd>Telescope lsp_definitions<cr>",
            desc = "[g]oto [d]efinition",
        },
        {
            "gr",
            "<cmd>Telescope lsp_references<cr>",
            desc = "[g]oto [r]eferences",
        },
        {
            "gI",
            "<cmd>Telescope lsp_implementations<cr>",
            desc = "[g]oto [I]mplementation",
        },
        {
            "gy",
            "<cmd>Telescope lsp_type_definitions<cr>",
            desc = "[g]oto t[y]pe definition",
        },
        -- General Telescope pickers
        {
            "<leader>Fr",
            "<cmd>Telescope oldfiles<cr>",
            desc = "[r]ecent files",
        },
        {
            "<leader>Fg",
            "<cmd>Telescope git_status<cr>",
            desc = "[g]it status",
        },
        {
            "<leader>Fw",
            function() require("telescope.builtin").grep_string() end,
            desc = "search current [w]ord",
            mode = { "n", "v" },
        },
        {
            "<leader>Fo",
            function()
                require("telescope.builtin").live_grep({
                    grep_open_files = true,
                    prompt_title = "Live Grep in Open Files",
                })
            end,
            desc = "grep [o]pen files",
        },
        {
            "<leader>Fc",
            function()
                require("telescope.builtin").find_files({
                    cwd = vim.fn.stdpath("config"),
                    follow = true,
                })
            end,
            desc = "[c]onfig files",
        },
        { "<leader>Fh", "<cmd>Telescope help_tags<cr>", desc = "[h]elp tags" },
        { "<leader>Fk", "<cmd>Telescope keymaps<cr>", desc = "[k]eymaps" },
        {
            "<leader>Fm",
            "<cmd>Telescope commands<cr>",
            desc = "[m]odule commands",
        },
        {
            "<leader>Fd",
            "<cmd>Telescope diagnostics<cr>",
            desc = "[d]iagnostics",
        },
        {
            "<leader>F.",
            "<cmd>Telescope resume<cr>",
            desc = "[.] resume search",
        },
        {
            "<leader>F?",
            "<cmd>Telescope builtin<cr>",
            desc = "[?] telescope builtins",
        },
        -- Telescope LSP symbol finders
        {
            "<leader>Fs",
            "<cmd>Telescope lsp_document_symbols<cr>",
            desc = "LSP document [s]ymbols",
        },
        {
            "<leader>FS",
            "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
            desc = "LSP workspace [S]ymbols",
        },
    },
    opts = {
        defaults = {
            layout_config = {
                horizontal = {
                    preview_width = 0.6,
                },
            },
        },
        extensions = {
            ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
    },
    config = function(plugin, tsp_opts)
        local tsp = require(plugin.main)
        tsp.setup(tsp_opts)

        tsp.load_extension("fzf")
        tsp.load_extension("ui-select")
    end,
}
