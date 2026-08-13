# Neovim Config

Personal Neovim configuration focused on modularity, and maintainability.
Originally based on
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).

## At a Glance

- **Plugin Manager:** [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Bootstrapping:** Installed via Neovim 0.12+
[`vim.pack`](https://neovim.io/doc/user/pack/) API
- **Theme:** [bamboo.nvim](https://github.com/ribru17/bamboo.nvim) (vulgaris
variant)

## Requirements

- Neovim 0.12 or higher
- Required binaries: `git`, `make`, `unzip`, `rg`, `nvr`, `lazygit`, `jb`

## Installation

Clone the repository into your Neovim configuration directory:

```bash
git clone https://github.com/103sbavert/nvim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
```

## Directory Structure

```plain
nvim
├─ .*
├─ README.md
├─ init.lua
├─ *-lock.json
└─ lua
   └─ config
      ├─ health.lua
      ├─ <module>.lua
      └─ plugins
         ├─ <simple-plugin>.lua
         └─ <complex-feature>/
            ├─ init.lua
            └─ <helper>.lua
```

### Path Conventions

- `init.lua`: This is the main entry point. It contains basic configuration
that does not require external dependencies, theme setup, `lazy.nvim`
bootstrapping via `vim.pack`, and module imports.
- `lua/config/health.lua`: Checks required host binaries, run only by explicit
invocation (`:checkhealth`). Also, see [Requirements](#requirements).
- `lua/config/<module>.lua`: This contains more complex, but still non-plugin
settings or re-usable utilities for other modules.
- `lua/config/plugins/<simple-plugin>.lua`: Single-file plugin configurations.
Used when setup logic fits cleanly in one file named after the plugin or
feature.
- `lua/config/plugins/<complex-feature>/`: Multi-file plugin configurations.
Used when setup requires modularization across multiple files.
  - `init.lua`: Main entry point for the feature module.
  - `<module>.lua`: Reusable utilities or sub-configurations loaded by
  `init.lua`.
