return {
    "andre-kotake/nvim-chezmoi",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
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

        require("config.plugins.chezmoi.auto_commands")
        require("config.plugins.chezmoi.template")

        local function apply_chezmoi()
            local utils = require("config.plugins.chezmoi.utils")
            local cmd_apply = require("nvim-chezmoi.chezmoi.commands.apply")
            local file = vim.api.nvim_buf_get_name(0)
            utils.is_src_file(file, function(is_src)
                if is_src then
                    cmd_apply:async({ "--source-path", file })
                else
                    cmd_apply:async({})
                end
            end)
        end

        local mappings = {
            e = {
                "<Cmd>ChezmoiEdit<Cr>",
                "[e]dit a chezmoi source file",
            },
            a = {
                apply_chezmoi,
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
