--- @type LazySpec
return {
    "103sbavert/nvim-chezmoi",
    dependencies = {
        "nvim-mini/mini.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "folke/which-key.nvim",
    },
    event = "VeryLazy",
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
    cmd = {
        "ChezmoiApply",
        "ChezmoiEdit",
        "ChezmoiManaged",
        "ChezmoiFiles",
    },
    keys = function()
        local utils = require("config.plugins.chezmoi.utils")
        local apply_utils = require("config.plugins.chezmoi.apply_utils")

        return {
            {
                "<leader>ze",
                utils.edit_chezmoi,
                desc = "[e]dit source file",
            },
            {
                "<leader>za",
                apply_utils.apply_chezmoi,
                desc = "[a]pply to target",
            },
            {
                "<leader>zs",
                "<Cmd>ChezmoiManaged<Cr>",
                desc = "[s]earch managed files",
            },
        }
    end,
    config = function(plugin, opts)
        require(plugin.main).setup(opts)
        require("config.plugins.chezmoi.statusline")
        require("config.plugins.chezmoi.template")
        local aucmd = require("config.plugins.chezmoi.aucmd")

        -- manual invocation on initialization if the aucmds registered too for first buffer
        if not vim.g.initial_trigger_done then
            aucmd.chezmoi_edit_autocmd_cb({
                buf = 0,
            })
        end
    end,
}
