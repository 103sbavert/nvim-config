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
        "LazyGitLog",
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>gl", "<cmd>LazyGitCurrentFile<cr>", desc = "[l]azyGit" },
    },
    ---@type LazyGitConfig
    opts = {
        floating_window = {
            scaling_factor = 0.9,
            winblend = 0,
            use_plenary = false,
            border = "none",
        },
        neovim_remote = vim.fn.executable("nvr") == 1,
        config_file_path = nil,
        on_exit_callback = nil,
    },
    config = true,
}
