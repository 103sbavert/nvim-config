---
--- Because most plugins are hosted on GitHub, you can use the helper
--- function to have less repetition in the following sections.
--- @param repo string
--- @return string
function _G.gh(repo) return "https://github.com/" .. repo end

-- Initial recommended configurations
do
    -- Enable faster startup by caching compiled Lua modules
    vim.loader.enable()

    -- Set <space> as the leader key
    -- See `:help mapleader`
    --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- Set to true if you have a Nerd Font installed and selected in the terminal
    vim.g.have_nerd_font = true

    -- [[ Setting options ]]
    --  See `:help vim.o`
    -- NOTE: You can change these options as you wish!
    --  For more options, you can see `:help option-list`

    -- Make line numbers default
    vim.o.number = true

    -- Tab size
    vim.o.shiftwidth = 4
    vim.o.tabstop = 4

    -- enable relative line numbers
    vim.o.relativenumber = true

    -- Enable mouse mode, can be useful for resizing splits for example!
    vim.o.mouse = "a"

    -- Don't show the mode, since it's already in the status line
    vim.o.showmode = false

    -- Sync clipboard between OS and Neovim.
    --  Schedule the setting after `UiEnter` because it can increase startup-time.
    --  Remove this option if you want your OS clipboard to remain independent.
    --  See `:help 'clipboard'`
    vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

    -- Enable break indent
    vim.o.breakindent = true

    -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
    vim.o.ignorecase = true
    vim.o.smartcase = true

    -- Keep signcolumn on by default
    vim.o.signcolumn = "yes"

    -- Decrease update time
    vim.o.updatetime = 250

    -- Decrease mapped sequence wait time
    vim.o.timeoutlen = 300

    -- Configure how new splits should be opened
    vim.o.splitright = true
    vim.o.splitbelow = true

    -- Enable spell check for camelCase words
    vim.o.spelloptions = "camel"

    -- Sets how neovim will display certain whitespace characters in the editor.
    --  See `:help 'list'`
    --  and `:help 'listchars'`
    --
    --  Notice listchars is set using `vim.opt` instead of `vim.o`.
    --  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
    --   See `:help lua-options`
    --   and `:help lua-guide-options`
    vim.o.list = true
    vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

    -- Preview substitutions live, as you type!
    vim.o.inccommand = "split"

    -- Show which line your cursor is on
    vim.o.cursorline = true

    -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
    -- instead raise a dialog asking if you wish to save the current file(s)
    -- See `:help 'confirm'`
    vim.o.confirm = true

    -- undo/redo history persists until session closes
    vim.o.undofile = false

    -- 8 lines of context around cursor when scrolling
    vim.o.scrolloff = 5

    -- move to the last character of the last line
    vim.keymap.set({ "n", "o", "x" }, "G", "G$", { noremap = true })

    -- move to the first character of the first line
    vim.keymap.set({ "n", "o", "x" }, "gg", "gg0", { noremap = true })

    if vim.fn.executable("nvr") == 1 then
        local editor_cmd = "nvr --remote-silent -o"

        local git_editor = "nvr --remote-tab-wait-silent +'set bufhidden=wipe'"

        vim.env.GIT_EDITOR = git_editor
        vim.env.EDITOR = editor_cmd
    end
end

-- Basic keymaps (built in vim actions, without any plugin dependency)
do
    local unnamed_buf_wipe_grp =
        vim.api.nvim_create_augroup("wipe_unnamed_buf", { clear = true })

    -- Remove unnamed buf (such as the empty buffer created when neovim is first opened) when they are hidden if:
    -- buffer is not modified
    -- buffer id is still valid at the next tick
    vim.api.nvim_create_autocmd("BufHidden", {
        group = unnamed_buf_wipe_grp,
        callback = function(ev)
            local buf_id = ev.buf
            local buf_name = vim.api.nvim_buf_get_name(buf_id)

            -- Skip if has name
            if buf_name ~= "" then
                return
            end

            -- Skip non-normal buffers
            if vim.bo[buf_id].buftype ~= "" then
                return
            end

            -- Skip if modified
            if vim.bo[buf_id].modified then
                return
            end

            -- Delete on next tick after hidden event
            vim.schedule(function()
                -- Check if buffer ID is still valid at this moment
                if vim.api.nvim_buf_is_valid(buf_id) then
                    -- Delete buffer
                    vim.api.nvim_buf_delete(buf_id, {})
                end
            end)
        end,
    })

    -- [[ Basic Keymaps ]]
    --  See `:help vim.keymap.set()`

    -- Clear highlights on search when pressing <Esc> in normal mode
    --  See `:help hlsearch`
    vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

    vim.keymap.set(
        { "n", "i", "v", "x", "s", "o", "c" },
        "<C-n>",
        "<Esc>",
        { desc = "Alias for <Esc>" }
    )

    -- TIP: Disable arrow keys in normal mode
    -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
    -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
    -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
    -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

    -- Key binds to navigate between tabs
    -- Use ALT+<h,l> to navigate between adjacent tabs
    vim.keymap.set(
        "n",
        "<A-h>",
        vim.cmd.tabprevious,
        { silent = true, desc = "Previous tab" }
    )
    vim.keymap.set(
        "n",
        "<A-l>",
        vim.cmd.tabnext,
        { silent = true, desc = "Next tab" }
    )

    -- Keybinds to make split navigation easier.
    --  Use CTRL+<hjkl> to switch between windows
    --
    --  See `:help wincmd` for a list of all window commands
    vim.keymap.set(
        "n",
        "<C-h>",
        "<C-w><C-h>",
        { desc = "Move focus to the left window" }
    )
    vim.keymap.set(
        "n",
        "<C-l>",
        "<C-w><C-l>",
        { desc = "Move focus to the right window" }
    )
    vim.keymap.set(
        "n",
        "<C-j>",
        "<C-w><C-j>",
        { desc = "Move focus to the lower window" }
    )
    vim.keymap.set(
        "n",
        "<C-k>",
        "<C-w><C-k>",
        { desc = "Move focus to the upper window" }
    )

    -- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
    -- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
    -- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
    -- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
    -- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

    -- [[ Basic Autocommands ]]
    --  See `:help lua-guide-autocommands`

    -- Highlight when yanking (copying) text
    --  Try it with `yap` in normal mode
    --  See `:help vim.hl.on_yank()`
    vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "Highlight when yanking (copying) text",
        group = vim.api.nvim_create_augroup(
            "kickstart-highlight-yank",
            { clear = true }
        ),
        callback = function() vim.hl.on_yank() end,
    })

    -- get rid of keyboard LSP shortcuts I don't like
    vim.keymap.del("n", "grn")
    vim.keymap.del("n", "grx")
    vim.keymap.del({ "n", "x" }, "gra")
    vim.keymap.del("n", "grr")
    vim.keymap.del("n", "gri")
    vim.keymap.del("n", "gO") -- [gs] with Snacks.picker is used instead
    vim.keymap.del("n", "grt")
end

-- lazy.nvim to load install all other plugins (except theme below)
vim.pack.add({ gh("folke/lazy.nvim") })

-- Default colorscheme
do
    vim.pack.add({ gh("ribru17/bamboo.nvim") })

    local c = require("bamboo.palette")["vulgaris"]
    local util = require("bamboo.util")
    local bg1 = util.darken(c.bg1, 0.03)
    local bg2 = util.darken(c.bg2, 0.03)
    local bg3 = util.darken(c.bg3, 0.03)

    require("bamboo").setup({
        style = "vulgaris",
        transparent = false,
        term_colors = true,
        code_style = {
            comments = { italic = true },
            keywords = { italic = true },
            diagnostics = {
                darker = true,
                undercurl = true,
                background = true,
            },
        },
        dim_inactive = true,
        colors = {
            bg1 = bg1,
            bg2 = bg2,
            bg3 = bg3,
        },
        highlights = {
            -- Elevated float surface (lighter background) used by blink menus, doc windows, and noice hover.
            ElevatedFloatNormal = { bg = bg1, fg = c.fg },
            ElevatedFloatBorder = { bg = bg1, fg = bg1 },
            ElevatedFloatSelection = { bg = bg2, bold = true },
            ElevatedFloatSeparator = { bg = bg1, fg = bg2 },
            ElevatedFloatCursorLine = { bg = bg2 },
            ElevatedFloatScrollThumb = { bg = bg3 },
            ElevatedFloatScrollGutter = { bg = bg2 },
            CmdlineBackground = { bg = c.bg_d },
            FloatBorder = { fg = c.purple },
            -- Noice Popup highlights
            NoiceConfirm = { link = "NormalFloat" },
            NoiceConfirmBorder = { link = "FloatBorder" },
            -- Blink highlights linked to above custom highlights
            BlinkCmpMenu = { link = "ElevatedFloatNormal" },
            BlinkCmpMenuBorder = { link = "ElevatedFloatBorder" },
            BlinkCmpMenuSelection = { link = "ElevatedFloatSelection" },
            BlinkCmpScrollBarThumb = { link = "ElevatedFloatScrollThumb" },
            BlinkCmpScrollBarGutter = { link = "ElevatedFloatScrollGutter" },
            BlinkCmpLabel = { link = "ElevatedFloatNormal" },
            BlinkCmpDoc = { link = "ElevatedFloatNormal" },
            BlinkCmpDocBorder = { link = "ElevatedFloatBorder" },
            BlinkCmpDocSeparator = { link = "ElevatedFloatSeparator" },
            BlinkCmpDocCursorLine = { link = "ElevatedFloatCursorLine" },
            BlinkCmpSignatureHelp = { link = "ElevatedFloatNormal" },
            BlinkCmpSignatureHelpBorder = { link = "ElevatedFloatBorder" },
        },
    })
    require("bamboo").load()
end

require("lazy").setup({
    spec = {
        { import = "config.plugins" },
        { "j-hui/fidget.nvim", config = true },
        { "windwp/nvim-autopairs", config = true },
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            config = true,
        },
        {
            "NMAC427/guess-indent.nvim",
            opts = {
                on_tab_options = {
                    ["expandtab"] = true,
                },
                on_space_options = {
                    ["expandtab"] = true,
                    ["tabstop"] = "detected",
                    ["softtabstop"] = "detected",
                    ["shiftwidth"] = "detected",
                },
            },
        },
        {
            "folke/todo-comments.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = true,
        },
        {
            name = "config.utils",
            dir = vim.fn.stdpath("config"),
        },
        {
            name = "config.mason",
            dir = vim.fn.stdpath("config"),
            dependencies = {
                "williamboman/mason.nvim",
                "williamboman/mason-lspconfig.nvim",
                "WhoIsSethDaniel/mason-tool-installer.nvim",
            },
        },
    },
    defaults = { lazy = false },
})
