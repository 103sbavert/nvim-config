local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = 0, desc = desc })
end

map(
    "n",
    "gx",
    "<cmd>Mdn inline_link open<CR>",
    "Open inline link URI under cursor"
)
map(
    "n",
    "gf",
    "<cmd>Mdn wikilink follow<CR>",
    "Open markdown file from WikiLink"
)
map(
    "n",
    "gF",
    "<cmd>Mdn wikilink follow_hor<CR>",
    "Open markdown file from WikiLink in a horizontal split"
)
map(
    "n",
    "<leader>mr",
    "<cmd>Mdn wikilink find_references<CR>",
    "Show references of WikiLink or current buffer"
)
map(
    "n",
    "<leader>ln",
    "<cmd>Mdn wikilink rename_references<CR>",
    "Rename references of WikiLink or current buffer"
)
map(
    "n",
    "<C-o>",
    "<cmd>Mdn history go_back<CR>",
    "Go back to previously visited Markdown buffer"
)
map(
    "n",
    "<C-S-o>",
    "<cmd>Mdn history go_forward<CR>",
    "Go to next visited Markdown buffer"
)

-- markdown specific keybinds
map(
    { "n", "v" },
    "<leader>mb",
    "<cmd>Mdn formatting strong_toggle<CR>",
    "Toggle strong formatting"
)
map(
    { "n", "v" },
    "<leader>mi",
    "<cmd>Mdn formatting emphasis_toggle<CR>",
    "Toggle emphasis formatting"
)
map(
    { "n", "v" },
    "<leader>mt",
    "<cmd>Mdn formatting task_list_toggle<CR>",
    "Toggle task list status"
)
map(
    { "n", "v" },
    "<leader>mk",
    "<cmd>Mdn inline_link toggle<CR>",
    "Toggle inline link"
)
