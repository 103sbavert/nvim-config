---@type LazySpec
return {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
        "saghen/blink.lib",
        "L3MON4D3/LuaSnip",
    },
    build = function()
        if not vim.fn.executable("cargo") then
            vim.notify(
                "Cargo is needed to build blink.cmp. Check if you have installed the Rust language toolchain or Cargo build tool",
                vim.log.levels.ERROR,
                {
                    title = "blink.cmp",
                }
            )
            return
        end

        require("blink.cmp").build():pwait()
    end,
    ---@type blink.cmp.Config
    opts = {
        cmdline = {
            enabled = true,
            keymap = {
                preset = "default",
            },
            completion = {
                documentation = { auto_show = true },
                trigger = {
                    show_on_blocked_trigger_characters = {},
                    show_on_x_blocked_trigger_characters = {},
                },
                list = { selection = { preselect = true, auto_insert = false } },
                menu = { auto_show = true },
                ghost_text = { enabled = false },
            },
        },
        keymap = { preset = "default" },
        appearance = {
            nerd_font_variant = "mono",
        },
        completion = {
            documentation = { auto_show = false },
            menu = { auto_show = true },
            list = { selection = { preselect = true, auto_insert = false } },
            ghost_text = { enabled = false },
        },
        sources = {
            default = { "lsp", "path", "snippets" },
        },
        fuzzy = { implementation = "rust" },
    },
}
