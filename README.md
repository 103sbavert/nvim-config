# NeoVim Config

This config is uses https://github.com/nvim-lua/kickstart.nvim as the base repository template but has diverged significantly.

## Structure

- Basic convenient keymaps and configurations from kickstart that do not depend on any plugins are kept in top level init.lua
- All the plugins are installed in init.lua using the new `vim.pack()` API
- All (except the colorscheme) plugin configurations are moved into the `lua/config/` directory
- `lua/config/init.lua` loads plugin configurations in the order I deemed fit (probably could be improved)
- Configurations for each plugin are in `lua/config/plugins`, generally in a `.lua` file named after the plugin or `.lua` files in the directory named after the plugin, however there are exceptions to this rule due to other constraints