-- Builtin gcc must go: the line toggle lives on gC instead.
vim.keymap.del("n", "gcc")

require("mini.comment").setup({
    mappings = {
        comment_line = "gC",
    },
})
