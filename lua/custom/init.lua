-- default theme
vim.cmd.colorscheme("adwaita")

require("guess-indent").setup({})
require("todo-comments").setup({ signs = false })

require("custom.utils")
require("custom.which_key")
require("custom.gitsigns")
require("custom.lsp")
require("custom.mini_nvim")
require("custom.noice")
require("custom.chezmoi")
require("custom.statusline")
require("custom.telescope")
require("custom.nvim_treesitter")
require("custom.spider")
