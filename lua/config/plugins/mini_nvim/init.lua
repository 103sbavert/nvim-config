return {
    "nvim-mini/mini.nvim",
    dependencies = { "andre-kotake/nvim-chezmoi" },
    config = function()
        require("config.plugins.mini_nvim.around_in")
        require("config.plugins.mini_nvim.surround")
        require("config.plugins.mini_nvim.statusline")
        require("config.plugins.mini_nvim.icons")
    end,
}
