---@type LazySpec
return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    main = "snacks",
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
        {
            "<leader>tt",
            function() Snacks.terminal.toggle() end,
            desc = "[t]erminal",
        },
    },
    ---@type snacks.Config
    opts = {
        bigfile = { enabled = true },
        explorer = {
            enabled = true,
            replace_netrw = true,
            trash = true,
        },
        indent = { enabled = true },
        input = { enabled = true },
        picker = {
            enabled = true,
            sources = {
                explorer = {
                    auto_close = true,
                    hidden = true,
                },
            },
        },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        statuscolumn = { enabled = true },
        terminal = { enabled = true },
        styles = {
            terminal = {
                keys = {
                    term_normal = {
                        "<C-n>",
                        "<C-\\><C-n>",
                        mode = "t",
                        expr = true,
                        desc = "Terminal normal",
                    },
                },
            },
        },
    },
    config = function(plugin, opts) require(plugin.main).setup(opts) end,
}
