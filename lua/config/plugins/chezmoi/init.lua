--- @type LazySpec
return {
    "103sbavert/nvim-chezmoi",
    dependencies = {
        "nvim-mini/mini.nvim",
        "nvim-lua/plenary.nvim",
        "folke/snacks.nvim",
        "j-hui/fidget.nvim",
    },
    main = "nvim-chezmoi",
    event = "VeryLazy",
    lazy = false,
    opts = {
        debug = false,
        source_path = os.getenv("CHEZMOI_SOURCE_DIR"),
        edit = {
            apply_on_save = "never",
        },
        execute_template = {
            open_in = "split",
        },
    },
    keys = function()
        local actions = require("config.plugins.chezmoi.actions")

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
        require("config.plugins.chezmoi.statusline")
        require("config.plugins.chezmoi.template")
        require("config.plugins.chezmoi.aucmd")
    end,
}
