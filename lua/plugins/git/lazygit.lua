--- @type LazySpec
return {
    "103sbavert/lazygit.nvim",
    branch = "main",
    lazy = true,
    enabled = function()
        if vim.fn.executable("lazygit") == 0 then
            vim.notify(
                "Lazygit CLI is not installed, lazyvgit.nvim is disabled",
                vim.log.levels.WARN
            )
            return false
        end

        return true
    end,
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
