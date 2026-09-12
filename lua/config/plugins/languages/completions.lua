--- @type LazySpec
return {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
        "saghen/blink.lib",
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

        local cmp = require("blink.cmp")
        local avail = cmp.library_available()
        if avail then
            vim.notify(
                "blink.cmp native library already built",
                vim.log.levels.INFO,
                { title = "blink.cmp" }
            )
            return
        end

        cmp.build()
            :map(function()
                vim.schedule(function()
                    if cmp.library_available() then
                        pcall(
                            require("blink.cmp.fuzzy").set_implementation,
                            "rust"
                        )
                    end
                    vim.notify(
                        "blink.cmp built, Rust matcher active",
                        vim.log.levels.INFO,
                        { title = "blink.cmp" }
                    )
                end)
            end)
            :catch(function(err)
                vim.schedule(
                    function()
                        vim.notify(
                            "blink.cmp build failed: " .. tostring(err),
                            vim.log.levels.ERROR,
                            { title = "blink.cmp" }
                        )
                    end
                )
            end)
    end,
    --- @type blink.cmp.Config
    opts = {
        cmdline = {
            enabled = true,
            keymap = {
                preset = "default",
                ["<C-s>"] = { "show_signature", "hide_signature" },
                ["<C-k>"] = { "show_documentation", "hide_documentation" },
                ["<C-space>"] = { "show", "hide" },
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
        keymap = {
            preset = "default",
            ["<C-s>"] = { "show_signature", "hide_signature" },
            ["<C-k>"] = { "show_documentation", "hide_documentation" },
            ["<C-space>"] = { "show", "hide" },
        },
        appearance = {
            nerd_font_variant = "mono",
        },
        term = { enabled = false },
        completion = {
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 500,
            },
            menu = { auto_show = true },
            list = { selection = { preselect = true, auto_insert = false } },
            ghost_text = { enabled = false },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
        fuzzy = { implementation = "prefer_rust" },
        signature = { enabled = true },
    },
}
