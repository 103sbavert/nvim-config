--@type LazySpec
return {
    "103sbavert/lazygit.nvim",
    branch = "fix/commit-editor-integration",
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
        { "<leader>gl", "<cmd>LazyGitCurrentFile<cr>", desc = "[l]azyGit" },
    },
    config = true,
}
