return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    main = "snacks",
    ---@type snacks.Config
    keys = {
        {
            "\\",
            function()
                local explorer = Snacks.picker.get({ source = "explorer" })[1]

                if not explorer then
                    Snacks.explorer()
                elseif explorer:is_focused() then
                    vim.cmd.wincmd("p")
                else
                    explorer:focus()
                end
            end,
            desc = "[\\] Toggle Explorer Focus",
        },
        { "<leader>gl", function() Snacks.lazygit() end, desc = "[l]azyGit" },
    },
    opts = {
        bigfile = { enabled = true },
        explorer = {
            enabled = true,
            replace_netrw = true,
            trash = true,
        },
        indent = { enabled = true },
        input = { enabled = true },
        picker = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        statuscolumn = { enabled = true },
        scroll = { enabled = true },
        words = { enabled = true },
        lazygit = { enabled = true },
    },
    config = function(plugin, opts) require(plugin.main).setup(opts) end,
}
