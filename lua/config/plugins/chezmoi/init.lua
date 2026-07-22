return {
    "103sbavert/nvim-chezmoi",
    dependencies = {
        "nvim-mini/mini.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "folke/which-key.nvim",
    },
    config = function()
        require("nvim-chezmoi").setup({
            debug = false,
            source_path = os.getenv("CHEZMOI_SOURCE_DIR"),
            edit = {
                apply_on_save = "never",
            },
            execute_template = {
                open_in = "split",
            },
        })

        local register_chezmoi_keymap = create_keymap_group("Che[z]moi", "<leader>z", { "n" })

        require("config.plugins.chezmoi.statusline")
        require("config.plugins.chezmoi.auto_commands")
        require("config.plugins.chezmoi.template")

        local utils = require("config.plugins.chezmoi.utils")
        local apply_utils = require("config.plugins.chezmoi.apply_utils")

        local mappings = {
            e = {
                utils.edit_chezmoi,
                "[e]dit a chezmoi source file",
            },
            a = {
                apply_utils.apply_chezmoi,
                "[a]pply chezmoi changes",
            },
            s = {
                "<Cmd>ChezmoiManaged<Cr>",
                "[s]earch managed files",
            },
        }

        for key, def in pairs(mappings) do
            register_chezmoi_keymap(key, def[1], def[2])
        end
    end,
}
