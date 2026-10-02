-- [[ Basic Keymaps ]]
-- Basic keymaps (built in vim actions, without any plugin dependency)

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Toggle wrap
vim.keymap.set(
    "n",
    "<leader>tw",
    function() vim.wo[0].wrap = not vim.wo[0].wrap end,
    { desc = "[w]rap" }
)

-- Sane gg and G behavior
-- Move to the last character of the last line
vim.keymap.set({ "n", "o", "x" }, "G", function()
    local last_line = vim.api.nvim_buf_line_count(0)
    local last_col = #vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] - 1
    vim.api.nvim_win_set_cursor(0, { last_line, math.max(0, last_col) })
end, { noremap = true })

-- Move to the first character of the first line
vim.keymap.set(
    { "n", "o", "x" },
    "gg",
    function() vim.api.nvim_win_set_cursor(0, { 1, 0 }) end,
    { noremap = true }
)

-- Custom character and line motion remaps
vim.keymap.set({ "n", "o", "x", "v" }, "0", "0", { desc = "First character" })
vim.keymap.set(
    { "n", "o", "x", "v" },
    "=",
    "g_",
    { desc = "Last non-ws character" }
)
vim.keymap.set(
    { "n", "o", "x", "v" },
    "-",
    "_",
    { desc = "First non-ws character" }
)
vim.keymap.set({ "n", "o", "x", "v" }, "$", "=", { desc = "Indent (op)" })
vim.keymap.set(
    { "n", "o", "x", "v" },
    "_",
    "-",
    { desc = "Start of previous line" }
)
vim.keymap.set({ "n", "o", "x", "v" }, "g_", "$", { desc = "Last character" })

-- Terminal kitty-keyboard-protocol fix (<C-@> -> <C-Space>)
vim.keymap.set(
    { "n", "i", "v", "x", "s", "o", "c", "t", "l" },
    "<C-@>",
    "<C-Space>",
    { remap = true }
)

-- Register custom file types handled by some plugins
vim.filetype.add({
    pattern = {
        [".*%.gitlab%-ci.*%.ya?ml"] = "yaml.gitlab",
        [".*%.tmpl"] = "gotmpl",
    },
})

-- Exit to Normal mode
vim.keymap.set(
    { "i", "c", "v", "x", "s", "o", "t", "l" },
    "<C-n>",
    "<C-\\><C-n>",
    { desc = "Exit to Normal mode" }
)

-- Key binds to navigate between tabs (ALT+<h,l>)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<A-h>",
    vim.cmd.tabprevious,
    { silent = true, desc = "Previous tab" }
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<A-l>",
    vim.cmd.tabnext,
    { silent = true, desc = "Next tab" }
)

-- Move current buffer/window to a new tab
vim.keymap.set(
    { "n", "i", "", "t" },
    "<A-t>",
    function() vim.cmd.wincmd("T") end,
    { silent = true, desc = "Move window to new tab" }
)

-- Switch between split windows (CTRL+<hjkl>)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-h>",
    function() vim.cmd.wincmd("h") end
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-j>",
    function() vim.cmd.wincmd("j") end
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-k>",
    function() vim.cmd.wincmd("k") end
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-l>",
    function() vim.cmd.wincmd("l") end
)

-- Move window positions in split layout
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-S-h>",
    "<C-w>H",
    { desc = "Move window to the left" }
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-S-l>",
    "<C-w>L",
    { desc = "Move window to the right" }
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-S-j>",
    "<C-w>J",
    { desc = "Move window to the lower" }
)
vim.keymap.set(
    { "n", "i", "x", "t" },
    "<C-S-k>",
    "<C-w>K",
    { desc = "Move window to the upper" }
)

-- [[ Merged LazyVim Enhancements ]]

-- Better indenting (preserves visual selection)
vim.keymap.set("x", "<", "<gv", { desc = "Outdent selection" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent selection" })

-- Move Lines
vim.keymap.set(
    "n",
    "<A-j>",
    "<cmd>execute 'move .+' . v:count1<cr>==",
    { desc = "Move line down" }
)
vim.keymap.set(
    "n",
    "<A-k>",
    "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==",
    { desc = "Move line up" }
)
vim.keymap.set(
    "i",
    "<A-j>",
    "<esc><cmd>m .+1<cr>==gi",
    { desc = "Move line down" }
)
vim.keymap.set(
    "i",
    "<A-k>",
    "<esc><cmd>m .-2<cr>==gi",
    { desc = "Move line up" }
)
vim.keymap.set(
    "v",
    "<A-j>",
    ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv",
    { desc = "Move selection down" }
)
vim.keymap.set(
    "v",
    "<A-k>",
    ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv",
    { desc = "Move selection up" }
)

-- Saner search direction (n always goes forward, N always goes backward)
vim.keymap.set(
    "n",
    "n",
    "'Nn'[v:searchforward].'zv'",
    { expr = true, desc = "Next Match" }
)
vim.keymap.set(
    "x",
    "n",
    "'Nn'[v:searchforward]",
    { expr = true, desc = "Next Match" }
)
vim.keymap.set(
    "o",
    "n",
    "'Nn'[v:searchforward]",
    { expr = true, desc = "Next Match" }
)
vim.keymap.set(
    "n",
    "N",
    "'nN'[v:searchforward].'zv'",
    { expr = true, desc = "Prev Match" }
)
vim.keymap.set(
    "x",
    "N",
    "'nN'[v:searchforward]",
    { expr = true, desc = "Prev Match" }
)
vim.keymap.set(
    "o",
    "N",
    "'nN'[v:searchforward]",
    { expr = true, desc = "Prev Match" }
)

-- Smart wrapped line movement (moves visual lines on wrap, logical lines on count)
vim.keymap.set(
    { "n", "x" },
    "j",
    "v:count == 0 ? 'gj' : 'j'",
    { expr = true, silent = true, desc = "Down" }
)
vim.keymap.set(
    { "n", "x" },
    "<Down>",
    "v:count == 0 ? 'gj' : 'j'",
    { expr = true, silent = true, desc = "Down" }
)
vim.keymap.set(
    { "n", "x" },
    "k",
    "v:count == 0 ? 'gk' : 'k'",
    { expr = true, silent = true, desc = "Up" }
)
vim.keymap.set(
    { "n", "x" },
    "<Up>",
    "v:count == 0 ? 'gk' : 'k'",
    { expr = true, silent = true, desc = "Up" }
)
