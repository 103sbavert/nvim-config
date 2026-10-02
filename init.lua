---
--- Because most plugins are hosted on GitHub, you can use the helper
--- function to have less repetition in the following sections.
--- @param repo string
--- @return string
function _G.gh(repo) return "https://github.com/" .. repo end

-- [[ Basic Tweaks ]]
-- Quality of life tweaks that change default Vim behavior to be inline with
-- how humans use their PCs while staying out of the way
--  These modify default Vim behavior by setting or changing built-in Vim
--  options or update environment or global lua variables used by other modules
--  or commands
--
-- See `:help options`
-- See `:help internal-variables`
-- See `:help vim.o`
do
    -- Enable faster startup by caching compiled Lua modules
    vim.loader.enable()

    -- Set <space> as the leader key
    --
    -- See `:help mapleader`
    --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- used by lazydev config in module "config.plugins.languages.language-servers"
    vim.g.lazy_lua_ls = true
    -- Set to true if you have a Nerd Font installed and selected in the terminal
    vim.g.have_nerd_font = true

    -- Used by markdonw ftplugin for pandoc compilation
    vim.g.pandoc_pdf_engine = "typst"
    vim.g.pandoc_md_flavor = "gfm"

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
    --
    -- See `:help 'clipboard'`
    vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

    -- Enable break indent
    vim.o.breakindent = true

    -- Case-insensitive searching UNLESS \C or one or more capital letters in
    -- the search term
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

    -- Sets how Neovim will display certain whitespace characters in the
    -- editor.
    --
    -- See `:help 'list'`
    -- See `:help 'listchars'`
    vim.o.list = true

    -- `vim.opt` provides an interface for conveniently interacting with
    -- `vim.o` tables.
    --
    -- See `:help vim.opt`
    vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

    -- Preview substitutions live, as you type!
    vim.o.inccommand = "split"

    -- Show which line your cursor is on
    vim.o.cursorline = true

    -- if performing an operation that would fail due to unsaved changes in the
    -- buffer (like `:q`), instead raise a dialog asking if you wish to save
    -- the current file(s)
    --
    -- See `:help 'confirm'`
    vim.o.confirm = true

    -- undo/redo history persists until session closes
    vim.o.undofile = false

    -- number of lines below and above the cursor to always keep in view when
    -- scrolling
    vim.o.scrolloff = 4

    -- Don't wrap the text
    vim.o.wrap = false

    -- set $EDITOR and $GIT_EDITOR to allow external commands launched from
    -- within Neovim to use the running Neovim instance instead of opening
    -- nested instances
    --
    -- See `:help vim.env`
    if vim.fn.executable("nvr") == 1 then
        local editor_cmd = "nvr --remote-silent -o"
        local git_editor = "nvr --remote-tab-wait-silent +'set bufhidden=wipe'"

        vim.env.GIT_EDITOR = git_editor
        vim.env.EDITOR = editor_cmd
    end
end

require("config.autocmds")
require("config.keys")

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

    local hl_write = util.blend(bg1, c.blue, 0.2)
    local hl_read = util.blend(bg1, c.green, 0.1)
    local hl_text = util.blend(bg1, c.green, 0.1)

    -- Dap sign highlights
    local hl_dap_breakpoint_text = util.darken(c.coral, 0.35)
    local hl_dap_stopped_text = util.darken(c.orange, 0.35)
    local hl_dap_breakpoint_rejected = util.darken(c.yellow, 0.35)

    -- Line HL
    local hl_dap_stopped_line = util.darken(c.orange, 0.85, bg1)

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
            NormalFloat = { bg = c.bg_d },
            FloatBorder = { fg = c.purple },
            -- LSP highlights
            LspReferenceWrite = { bg = hl_write },
            LspReferenceRead = { bg = hl_read },
            LspReferenceText = { bg = hl_text },
            -- Noice Popup highlights
            NoiceConfirm = { link = "NormalFloat" },
            NoiceConfirmBorder = { link = "FloatBorder" },
            -- Dap sign highlights
            DapBreakpoint = { fg = hl_dap_breakpoint_text },
            DapBreakpointRejected = { fg = hl_dap_breakpoint_rejected },
            DapStopped = { fg = hl_dap_stopped_text },
            DapStoppedLine = { bg = hl_dap_stopped_line },
        },
    })
    require("bamboo").load()
end

require("lazy").setup({
    --- @type LazySpec[]
    spec = {
        { import = "config.plugins" },
        { "windwp/nvim-autopairs", config = true },
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            config = true,
        },
        {
            "NMAC427/guess-indent.nvim",
            opts = {
                auto_cmd = true,
                --- @type vim.bo
                on_tab_options = {
                    expandtab = true,
                    softtabstop = -1,
                },
                --- @type vim.bo
                on_space_options = {
                    expandtab = true,
                    tabstop = "detected",
                    softtabstop = "detected",
                    shiftwidth = "detected",
                },
            },
        },
        {
            "folke/todo-comments.nvim",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = true,
        },
        {
            "j-hui/fidget.nvim",
            lazy = true,
            config = function()
                require("fidget").setup({
                    progress = {
                        ignore_done_already = true,
                        ignore_empty_message = true,
                        display = {
                            render_limit = 3,
                            done_ttl = 1,
                        },
                    },
                })
            end,
        },
        {
            name = "config.su",
            main = "config.su",
            dir = vim.fn.stdpath("config"),
            dependencies = { "mini.nvim" },
            config = true,
        },
        {
            name = "config.utils",
            main = "config.utils",
            dir = vim.fn.stdpath("config"),
            lazy = true,
            dependencies = "j-hui/fidget.nvim",
        },
    },
    defaults = { lazy = false },
})
