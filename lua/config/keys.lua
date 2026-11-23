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

-- Toggle-open the terminal
vim.keymap.set(
    { "n", "o", "t", "v" },
    "<C-/>",
    require("config.utils").toggle_term,
    { desc = "Open terminal" }
)

-- Sane gg and G behavior
-- Move to the last character of the last line
vim.keymap.set({ "n", "o", "v" }, "G", function()
    local last_line = vim.api.nvim_buf_line_count(0)
    local last_col = #vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] - 1
    vim.api.nvim_win_set_cursor(0, { last_line, math.max(0, last_col) })
end, { noremap = true })

-- Move to the first character of the first line
vim.keymap.set(
    { "n", "o", "v" },
    "gg",
    function() vim.api.nvim_win_set_cursor(0, { 1, 0 }) end,
    { noremap = true }
)

-- Custom character and line motion remaps
vim.keymap.set({ "n", "o", "v" }, "0", "0", { desc = "First character" })
vim.keymap.set({ "n", "o", "v" }, "=", "g_", { desc = "Last non-ws character" })
vim.keymap.set({ "n", "o", "v" }, "-", "_", { desc = "First non-ws character" })
vim.keymap.set({ "n", "o", "v" }, "$", "=", { desc = "Indent (op)" })
vim.keymap.set({ "n", "o", "v" }, "_", "-", { desc = "Start of previous line" })
vim.keymap.set({ "n", "o", "v" }, "g_", "$", { desc = "Last character" })

-- Terminal kitty-keyboard-protocol fix (<C-@> -> <C-Space>)
vim.keymap.set(
    { "n", "i", "v", "o", "c", "t", "l" },
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
    { "i", "c", "v", "o", "t", "l" },
    "<C-n>",
    "<C-\\><C-n>",
    { desc = "Exit to Normal mode" }
)

-- Key binds to navigate between tabs (ALT+<h,l>)
vim.keymap.set(
    { "n", "i", "v", "t" },
    "<A-q>",
    vim.cmd.tabprevious,
    { silent = true, desc = "Previous tab" }
)
vim.keymap.set(
    { "n", "i", "v", "t" },
    "<A-e>",
    vim.cmd.tabnext,
    { silent = true, desc = "Next tab" }
)

-- Move current buffer/window to a new tab
vim.keymap.set(
    { "n", "i", "v", "t" },
    "<A-t>",
    function() vim.cmd.wincmd("T") end,
    { silent = true, desc = "Move window to new tab" }
)

-- Move current buffer/window to a new tab
vim.keymap.set(
    { "n", "i", "v", "t" },
    "<A-w>",
    vim.cmd.tabclose,
    { silent = true, desc = "Move window to new tab" }
)

-- Navigate split windows (CTRL+<hjkl>)
-- local win_nav_dirs = { h = "left", j = "down", k = "up", l = "right" }
-- for dir, name in pairs(win_nav_dirs) do
--     local key = "<C-" .. dir .. ">"
--     vim.keymap.set({ "n", "i", "v", "t" }, key, function()
--         if vim.api.nvim_win_get_config(0).relative ~= "" then
--             vim.api.nvim_feedkeys(vim.keycode(key), "t", false)
--             return
--         end
--         vim.cmd.wincmd(dir)
--     end, { desc = "Window " .. name })
-- end

-- Move window positions in split layout
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wH",
--     "<C-w>H",
--     { desc = "Move window left" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wL",
--     "<C-w>L",
--     { desc = "Move window right" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wJ",
--     "<C-w>J",
--     { desc = "Move window down" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wK",
--     "<C-w>K",
--     { desc = "Move window up" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>w=",
--     "<C-w>=",
--     { desc = "Equalize all splits" }
-- )

-- Resize windows
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wh",
--     "<cmd>vertical resize -3<cr>",
--     { desc = "Decrease width" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wj",
--     "<cmd>resize -3<cr>",
--     { desc = "Decrease height" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wk",
--     "<cmd>resize +3<cr>",
--     { desc = "Increase height" }
-- )
-- vim.keymap.set(
--     { "n", "v" },
--     "<leader>wl",
--     "<cmd>vertical resize +3<cr>",
--     { desc = "Increase width" }
-- )

-- vim.keymap.set({ "n", "v" }, "<leader>wq", "<cmd>q<cr>", { desc = "Close" })

-- [[ Merged LazyVim Enhancements ]]

-- Better indenting (preserves visual selection)
vim.keymap.set("v", "<", "<gv", { desc = "Outdent selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent selection" })

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
    { "v", "o" },
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
    { "v", "o" },
    "N",
    "'nN'[v:searchforward]",
    { expr = true, desc = "Prev Match" }
)

-- Smart wrapped line movement (moves visual lines on wrap, logical lines on count)
vim.keymap.set(
    { "n", "v" },
    "j",
    "v:count == 0 ? 'gj' : 'j'",
    { expr = true, silent = true, desc = "Down" }
)
vim.keymap.set(
    { "n", "v" },
    "<Down>",
    "v:count == 0 ? 'gj' : 'j'",
    { expr = true, silent = true, desc = "Down" }
)
vim.keymap.set(
    { "n", "v" },
    "k",
    "v:count == 0 ? 'gk' : 'k'",
    { expr = true, silent = true, desc = "Up" }
)
vim.keymap.set(
    { "n", "v" },
    "<Up>",
    "v:count == 0 ? 'gk' : 'k'",
    { expr = true, silent = true, desc = "Up" }
)

-- Add undo break-points
vim.keymap.set("i", ",", ",<c-g>u")
vim.keymap.set("i", ".", ".<c-g>u")
vim.keymap.set("i", ";", ";<c-g>u")
