---@type LazySpec
return {
    "103sbavert/lazygit.nvim",
    lazy = true,
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>gl", "<cmd>LazyGit<cr>", desc = "[l]azyGit" },
    },
    config = function()
        vim.g.lazygit_floating_window_scaling_factor = 0.9 -- scaling factor for floating window
        vim.g.lazygit_floating_window_use_plenary = 1 -- use plenary.nvim to manage floating window if available
        vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed
    end,
}
