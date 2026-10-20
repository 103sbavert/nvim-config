--- @type LazySpec
return {
    "103sbavert/lazygit.nvim",
    branch = "main",
    lazy = true,
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
        "LazyGitLog",
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>gz", "<cmd>LazyGitCurrentFile<cr>", desc = "la[z]yGit" },
    },
    config = true,
}
