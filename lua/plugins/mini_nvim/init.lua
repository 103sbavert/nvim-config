--- @type LazySpec
return {
    "nvim-mini/mini.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
    },
    config = function()
        require("plugins.mini_nvim.around_in")
        require("plugins.mini_nvim.surround")
        require("plugins.mini_nvim.statusline")
        require("plugins.mini_nvim.comment")
        require("plugins.mini_nvim.icons")
    end,
}
