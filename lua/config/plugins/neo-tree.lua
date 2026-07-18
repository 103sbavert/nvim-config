-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    init = function() vim.keymap.set("n", "\\", "<Cmd>Neotree reveal<CR>", { desc = "NeoTree reveal", silent = true }) end,
    config = function()
        require("neo-tree").setup({
            sources = {
                "filesystem",
                "buffers",
            },
            enable_opened_markers = true,
            source_selector = {
                winbar = true,
                sources = {
                    { source = "filesystem" },
                    { source = "buffers" },
                },
                truncation_character = "…",
            },
            default_component_configs = {
                name = {
                    highlight_opened_files = false,
                },
                modified = {
                    symbol = "*",
                    highlight = "NeoTreeModified",
                },
                git_status = {
                    symbols = {
                        -- Change type
                        added = "A",
                        deleted = "D",
                        modified = "M",
                        renamed = "R",
                        -- Status type
                        untracked = "?",
                        ignored = ".",
                        unstaged = "~",
                        staged = "+",
                        conflict = "!",
                    },
                    align = "right",
                },
            },
            open_files_do_not_replace_types = { "nofile", "terminal", "Trouble", "qf", "edgy" },
            filesystem = {
                filtered_items = {
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
        })

        local vulgaris = require("bamboo.palette").vulgaris
        vim.api.nvim_set_hl(0, "NeoTreeTabActive", { fg = vulgaris.contrast, bg = vulgaris.bg_yellow, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeTabInactive", { fg = vulgaris.light_grey, bg = vulgaris.bg_d })
        vim.api.nvim_set_hl(0, "NeoTreeTabSeparatorActive", { fg = vulgaris.bg_d, bg = vulgaris.bg3 })
        vim.api.nvim_set_hl(0, "NeoTreeTabSeparatorInactive", { fg = vulgaris.bg_d, bg = vulgaris.bg_d })
    end,
}
