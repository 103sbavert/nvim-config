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
            width = math.floor(vim.o.columns * 0.35),
            height = { max = math.floor(vim.o.lines * 0.5) },
        },
        keys = {
            scroll_up = "<C-A>",
            scroll_down = "<C-D>",
        },
        filter = function(mapping)
            return mapping.desc and vim.trim(mapping.desc) ~= "" -- exclude if no descripton is found
        end,
        spec = {
            -- `g` prefix groups
            -- { "gc", desc = "Comment", mode = "n" },
            { "gq", desc = "Format (smart)", mode = "n" },
            { "gw", desc = "Format (dumb)", mode = "n" },
            { "ga", group = "[g]o [t]o c[a]lls", mode = "n" },

            -- `<leader>` prefix groups
            { "<leader>g", group = "[g]it", mode = "n" },
            { "<leader>b", group = "[b]reakpoints", mode = "n" },
            { "<leader>t", group = "[t]oggle", mode = "n" },
            { "<leader>z", group = "Che[z]moi", mode = "n" },
            { "<leader>s", group = "[s]earch", mode = "n" },
            { "<leader>l", group = "[l]SP", mode = "n" },
        },
    },
}
