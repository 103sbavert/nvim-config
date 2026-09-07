--- @type LazySpec
return {
    "folke/which-key.nvim",
    --- @type wk.Opts
    opts = {
        delay = 300,
        preset = "helix",
        plugins = {
            marks = true,
            registers = true,
            spelling = { enabled = true },
            presets = {
                operators = true,
                motions = true,
                text_objects = true,
                windows = true,
                nav = true,
                z = true,
                g = true,
            },
        },
        icons = { mappings = false },
        win = {
            width = math.floor(vim.o.columns * 0.30),
            height = { max = math.floor(vim.o.lines * 0.6) },
        },
        keys = {
            scroll_up = "<C-a>",
            scroll_down = "<C-b>",
        },
        filter = function(mapping)
            return mapping.desc and vim.trim(mapping.desc) ~= "" -- exclude if no descripton is found
        end,
        spec = {
            -- `g` prefix groups
            -- { "gc", desc = "Comment", mode = "n" },
            { "gq", desc = "Format (smart)", mode = { "x", "n" } },
            { "gw", desc = "Format (dumb)", mode = { "x", "n" } },
            { "gx", desc = "open URI/path under cusor", mode = { "x", "n" } },

            -- `<leader>` prefix groups
            { "<leader>g", group = "[g]it", mode = { "x", "n" } },
            { "<leader>b", group = "[b]reakpoints", mode = "n" },
            { "<leader>t", group = "[t]oggle", mode = "n" },
            { "<leader>z", group = "Che[z]moi", mode = "n" },
            { "<leader>s", group = "[s]earch", mode = { "x", "n" } },
            { "<leader>l", group = "[l]SP", mode = { "x", "n" } },
        },
    },
}
