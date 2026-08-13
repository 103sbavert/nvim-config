---@type LazySpec
return {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    init = function()
        vim.keymap.set(
            "n",
            "\\",
            "<Cmd>Neotree reveal<CR>",
            { desc = "NeoTree reveal", silent = true }
        )
    end,
    opts = {
        enable_opened_markers = true,
        default_component_configs = {
            name = {
                highlight_opened_files = true,
            },
            modified = {
                symbol = "＊",
                highlight = "NeoTreeModified",
            },
            git_status = {
                symbols = require("config.utils").neotree_git_glyphs[vim.g.have_nerd_font],
            },
        },
        open_files_do_not_replace_types = {
            "nofile",
            "terminal",
            "Trouble",
            "qf",
            "edgy",
        },
        filesystem = {
            filtered_items = {
                hide_gitignored = true,
                hide_ignored = true,
                show_hidden_count = true,
                hide_dotfiles = false,
                hide_by_name = {
                    "bin",
                    "node_modules",
                    "lib",
                    "obj",
                },
                never_show = {
                    ".git",
                },
            },
            use_libuv_file_watcher = true,
            window = {
                mappings = {
                    ["\\"] = "close_window",
                },
            },
        },
    },
}
