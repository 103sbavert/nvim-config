-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    init = function() vim.keymap.set("n", "\\", "<Cmd>Neotree reveal<CR>", { desc = "NeoTree reveal", silent = true }) end,
    config = function()
        require("neo-tree").setup({
            filesystem = {
                window = {
                    mappings = {
                        ["\\"] = "close_window",
                    },
                },
            },
        })
    end,
}
