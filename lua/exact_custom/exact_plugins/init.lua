---Helper function for github-hosted nvim plugins, copied from kickstart's parent init.lua
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- Adwaita color schema from github
vim.pack.add { gh 'Mofiqul/adwaita.nvim' }
vim.g.adwaita_darker = false
vim.cmd.colorscheme 'adwaita'

-- noice plugin for fancy dialogs
vim.pack.add { gh 'MunifTanjim/nui.nvim', gh 'rcarriga/nvim-notify', gh 'folke/noice.nvim' }

-- easy lsp
vim.pack.add { gh 'stevearc/conform.nvim' }

-- plugin for chezmoi commands and tools
vim.pack.add { gh 'xvzc/chezmoi.nvim' }

-- Iterate over all Lua files in the plugins directory and load them
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
    if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
        local module = file_name:gsub('%.lua$', '')
        require('custom.plugins.' .. module)
    end
end

-- enable relative line numbers
vim.o.relativenumber = true
-- undo/redo history persists until session closes
vim.o.undofile = false
-- 8 lines of context around cursor when scrolling
vim.o.scrolloff = 8
-- move to the last character of the last line
vim.keymap.set({ 'n', 'o', 'x' }, 'G', 'G$', { noremap = true })
-- move to the first character of the first line
vim.keymap.set({ 'n', 'o', 'x' }, 'gg', 'gg0', { noremap = true })
