--- @type LazySpec
return {
    "103sbavert/nvim-chezmoi",
    dependencies = {
        "nvim-mini/mini.nvim",
        "nvim-lua/plenary.nvim",
        "folke/snacks.nvim",
        "j-hui/fidget.nvim",
    },
    event = "VeryLazy",
    lazy = false,
    main = "nvim-chezmoi",
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
        local edit_utils = require("config.plugins.chezmoi.edit_utils")
        local apply_utils = require("config.plugins.chezmoi.apply_utils")

        return {
            {
                "<leader>ze",
                edit_utils.edit_chezmoi,
                desc = "[e]dit source file",
            },
            {
                "<leader>za",
                apply_utils.apply_chezmoi_async,
                desc = "[a]pply to target",
            },
        }
    end,
    config = function(plugin, opts)
        --- @module "nvim-chezmoi"
        require(plugin.main).setup(opts)
        require("config.plugins.chezmoi.statusline")
        require("config.plugins.chezmoi.template")
        require("config.plugins.chezmoi.aucmd")
    end,
}
