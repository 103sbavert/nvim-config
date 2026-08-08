# NeoVim Config

This config is uses [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
as the base repository template but has diverged significantly.

## Structure

- Basic keymaps and sensible (or rather, preferred) configurations from
kick start that do not depend on external plugins
on any plugins are kept in top level `init.lua`
- lazy.vim and bamboo vulagaris color theme are installed using `vim.pack`
from NeoVim 0.12
- Complex standalone configurations that are not dependent on any external
plugins are sourced directly in lazy.vim as local modules from `config/`
- All the plugins are installed by importing lazy specs from `lua/config/plugins`
where they are also configured
