-- [[ Fuzzy Finder (files, lsp, etc) ]]
--
-- Telescope is a fuzzy finder that comes with a lot of different things that
-- it can fuzzy find! It's more than just a "file finder", it can search
-- many different aspects of Neovim, your workspace, LSP, and more!
--
-- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
-- so feel free to experiment and see what you like!
--
-- The easiest way to use Telescope, is to start by doing something like:
--  :Telescope help_tags
--
-- After running this command, a window will open up and you're able to
-- type in the prompt window. You'll see a list of `help_tags` options and
-- a corresponding preview of the help.
--
-- Two important keymaps to use while in Telescope are:
--  - Insert mode: <c-/>
--  - Normal mode: ?
--
-- This opens a window that shows you all of the keymaps for the current
-- Telescope picker. This is really useful to discover what Telescope can
-- do as well as how to actually do it!

-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
    -- You can put your default mappings / updates / etc. in here
    --  All the info you're looking for is in `:help telescope.setup()`
    --
    -- defaults = {
    --   mappings = {
    --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
    --   },
    -- },
    -- pickers = {}
    extensions = {
        ["ui-select"] = { require("telescope.themes").get_dropdown() },
    },
})

-- Enable Telescope extensions if they are installed
pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "ui-select")

-- keymapping factory for the Search group
local map_search = create_keymap_group("[S]earch", "<leader>s", "n")

-- See `:help telescope.builtin`
local builtin = require("telescope.builtin")

map_search("h", builtin.help_tags, "[S]earch [H]elp")
map_search("k", builtin.keymaps, "[S]earch [K]eymaps")
map_search("f", builtin.find_files, "[S]earch [F]iles")
map_search("s", builtin.builtin, "[S]earch [S]elect Telescope")
map_search("g", builtin.live_grep, "[S]earch by [G]rep")
map_search("d", builtin.diagnostics, "[S]earch [D]iagnostics")
map_search("r", builtin.resume, "[S]earch [R]esume")
map_search(".", builtin.oldfiles, '[S]earch Recent Files ("." for repeat)')
map_search("c", builtin.commands, "[S]earch [C]ommands")
map_search("w", builtin.grep_string, "[S]earch current [W]ord", {}, { "n", "v" })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
map_search(
    "/",
    function()
        builtin.live_grep({
            grep_open_files = true,
            prompt_title = "Live Grep in Open Files",
        })
    end,
    "[S]earch [/] in Open Files"
)

-- Shortcut for searching your Neovim configuration files
map_search(
    "n",
    function() builtin.find_files({ cwd = vim.fn.stdpath("config"), follow = true }) end,
    "[S]earch [N]eovim files"
)

vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

-- Override default behavior and theme when searching
vim.keymap.set("n", "<leader>/", function()
    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 10,
        previewer = false,
    }))
end, { desc = "[/] Fuzzily search in current buffer" })
