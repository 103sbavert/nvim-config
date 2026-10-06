--- @type LazySpec
return {
    "103sbavert/nvim-chezmoi",
    branch = "main",
    dependencies = {
        "config.utils",
        "nvim-mini/mini.nvim",
        "nvim-lua/plenary.nvim",
        "folke/snacks.nvim",
        "j-hui/fidget.nvim",
    },
    main = "nvim-chezmoi",
    event = "BufReadPre " .. vim.fs.joinpath(vim.env.CHEZMOI_SOURCE_DIR, "*"),
    opts = {
        debug = false,
        source_path = vim.env.CHEZMOI_SOURCE_DIR,
        edit = {
            apply_on_save = "never",
        },
        execute_template = {
            open_in = "split",
        },
    },
    keys = function()
        local actions = require("plugins.chezmoi.actions")

        return {
            {
                "<leader>ze",
                actions.edit,
                desc = "[e]dit source file",
            },
            {
                "<leader>za",
                actions.apply,
                desc = "[a]pply to target",
            },
        }
    end,
    cmd = {
        "ChezmoiEdit",
        "ChezmoiApply",
        "ChezmoiManaged",
        "ChezmoiFiles",
    },
    config = function(plugin, opts)
        --- @module "nvim-chezmoi"
        require(plugin.main).setup(opts)
        require("plugins.chezmoi.statusline")
        require("plugins.chezmoi.template")
        require("plugins.chezmoi.aucmd")
    end,
}
