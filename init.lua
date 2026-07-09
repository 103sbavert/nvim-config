---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
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
    vim.g.have_nerd_font = false

    -- [[ Setting options ]]
    --  See `:help vim.o`
    -- NOTE: You can change these options as you wish!
    --  For more options, you can see `:help option-list`

    -- Make line numbers default
    vim.o.number = true

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
    vim.o.scrolloff = 8

    -- move to the last character of the last line

    vim.keymap.set({ "n", "o", "x" }, "G", "G$", { noremap = true })
    -- move to the first character of the first line

    vim.keymap.set({ "n", "o", "x" }, "gg", "gg0", { noremap = true })

    -- interpret <ext>.tmpl same as <ext>
    vim.filetype.add({
        pattern = {
            [".*%.([^%.]+)%.tmpl"] = function(_, _, ext) return ext end,
        },
    })
end

-- Basic keymaps (built in vim actions, without any plugin dependency)
do
    -- [[ Basic Keymaps ]]
    --  See `:help vim.keymap.set()`

    -- Clear highlights on search when pressing <Esc> in normal mode
    --  See `:help hlsearch`
    vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

    -- Diagnostic Config & Keymaps
    --  See `:help vim.diagnostic.Opts`
    vim.diagnostic.config({
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = { severity = { min = vim.diagnostic.severity.WARN } },

        -- Can switch between these as you prefer
        virtual_text = true, -- Text shows up at the end of the line
        virtual_lines = false, -- Text shows up underneath the line, with virtual lines

        -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
        jump = {
            on_jump = function(_, bufnr)
                vim.diagnostic.open_float({
                    bufnr = bufnr,
                    scope = "cursor",
                    focus = false,
                })
            end,
        },
    })

    vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

    -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
    -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
    -- is not what someone will guess without a bit more experience.
    --
    -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
    -- or just use <C-\><C-n> to exit terminal mode
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

    -- TIP: Disable arrow keys in normal mode
    -- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
    -- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
    -- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
    -- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

    -- Keybinds to make split navigation easier.
    --  Use CTRL+<hjkl> to switch between windows
    --
    --  See `:help wincmd` for a list of all window commands
    vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
    vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
    vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
    vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

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
        group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
        callback = function() vim.hl.on_yank() end,
    })

    -- get rid of keyboard LSP shortcuts I don't like
    vim.keymap.del("n", "grn")
    vim.keymap.del("n", "grx")
    vim.keymap.del("n", "gra")
    vim.keymap.del("n", "grr")
    vim.keymap.del("n", "gri")
    vim.keymap.del("n", "grt")
    vim.keymap.del("n", "gO")
end

-- vim.pack intro, build hooks
do
    -- [[ Intro to `vim.pack` ]]
    -- `vim.pack` is a new plugin manager built into Neovim,
    --  which provides a Lua interface for installing and managing plugins.
    --
    --  See `:help vim.pack`, `:help vim.pack-examples` or the
    --  excellent blog post from the creator of vim.pack and mini.nvim:
    --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
    --
    --  To inspect plugin state and pending updates, run
    --    :lua vim.pack.update(nil, { offline = true })
    --
    --  To update plugins, run
    --    :lua vim.pack.update()
    --
    --
    --  Throughout the rest of the config there will be examples
    --  of how to install and configure plugins using `vim.pack`.
    --
    --  In this section we set up some autocommands to run build
    --  steps for certain plugins after they are installed or updated.

    local function run_build(name, cmd, cwd)
        local result = vim.system(cmd, { cwd = cwd }):wait()
        if result.code ~= 0 then
            local stderr = result.stderr or ""
            local stdout = result.stdout or ""
            local output = stderr ~= "" and stderr or stdout
            if output == "" then
                output = "No output from build command."
            end
            vim.notify(("Build failed for %s:\n%s"):format(name, output), vim.log.levels.ERROR)
        end
    end

    -- This autocommand runs after a plugin is installed or updated and
    --  runs the appropriate build command for that plugin if necessary.
    --
    -- See `:help vim.pack-events`
    vim.api.nvim_create_autocmd("PackChanged", {
        callback = function(ev)
            local name = ev.data.spec.name
            local kind = ev.data.kind
            if kind ~= "install" and kind ~= "update" then
                return
            end

            if name == "telescope-fzf-native.nvim" and vim.fn.executable("make") == 1 then
                run_build(name, { "make" }, ev.data.path)
                return
            end

            if name == "LuaSnip" then
                if vim.fn.has("win32") ~= 1 and vim.fn.executable("make") == 1 then
                    run_build(name, { "make", "install_jsregexp" }, ev.data.path)
                end
                return
            end

            if name == "nvim-treesitter" then
                if not ev.data.active then
                    vim.cmd.packadd("nvim-treesitter")
                end
                vim.cmd("TSUpdate")
                return
            end
        end,
    })
end

-- Package installation
do
    -- Core lua library
    vim.pack.add({ gh("nvim-lua/plenary.nvim") })

    -- Color scheme
    do
        vim.pack.add({ gh("ribru17/bamboo.nvim") })

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
        })

        require("bamboo").load()
    end

    -- UI and Aesthetics
    vim.pack.add({
        gh("MunifTanjim/nui.nvim"),
        gh("rcarriga/nvim-notify"),
        gh("folke/noice.nvim"),
        gh("j-hui/fidget.nvim"),
    })

    -- Language Server Protocol and tool installers
    vim.pack.add({
        gh("neovim/nvim-lspconfig"),
        gh("mason-org/mason.nvim"),
        gh("mason-org/mason-lspconfig.nvim"),
        gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
    })

    -- Editing and Navigation Essentials
    vim.pack.add({
        gh("NMAC427/guess-indent.nvim"),
        gh("chrisgrieser/nvim-spider"),
        gh("nvim-neo-tree/neo-tree.nvim"),
        gh("folke/which-key.nvim"),
    })

    -- Coding, Formatting, and Snippets
    vim.pack.add({
        gh("nvim-treesitter/nvim-treesitter"),
        gh("stevearc/conform.nvim"),
        gh("rafamadriz/friendly-snippets"),
        gh("saghen/blink.cmp"),
        gh("L3MON4D3/LuaSnip"),
    })

    -- Git and External Tool Integrations
    vim.pack.add({
        gh("lewis6991/gitsigns.nvim"),
        gh("xvzc/chezmoi.nvim"),
        gh("folke/todo-comments.nvim"),
    })

    -- Language Server Extensions
    vim.pack.add({ gh("Hoffs/omnisharp-extended-lsp.nvim") })

    -- Plugin Suites / Ecosystems
    vim.pack.add({ gh("nvim-mini/mini.nvim") })

    -- Telescope plugins
    do
        local telescope_plugins = {
            gh("nvim-telescope/telescope.nvim"),
            gh("nvim-telescope/telescope-ui-select.nvim"),
        }

        if vim.fn.executable("make") == 1 then
            table.insert(telescope_plugins, gh("nvim-telescope/telescope-fzf-native.nvim"))
        end

        vim.pack.add(telescope_plugins)
    end
end

require("config")
