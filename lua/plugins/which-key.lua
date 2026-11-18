--- @type LazySpec
return {
    "folke/which-key.nvim",
    --- @module "which-key"
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
            { "gq", desc = "Format (smart)", mode = { "v", "n" } },
            { "gw", desc = "Format (dumb)", mode = { "v", "n" } },
            { "gx", desc = "Open URI/path under cusor", mode = { "v", "n" } },

            { "[", group = "Backwards" },
            { "]", group = "Forwards" },

            -- `<leader>` prefix groups
            { "<leader>d", group = "[d]ebug", mode = { "n" } },
            { "<leader>g", group = "[g]it", mode = { "v", "n" } },
            { "<leader>gd", group = "[d]iff", mode = { "n" } },
            { "<leader>b", group = "[b]reakpoints", mode = "n" },
            { "<leader>t", group = "[t]oggle", mode = "n" },
            { "<leader>z", group = "Che[z]moi", mode = "n" },
            { "<leader>s", group = "[s]earch", mode = { "v", "n" } },
            { "<leader>l", group = "[l]SP", mode = { "v", "n" } },

            -- `[w]indows` group and mappings
            { "<leader>w", group = "[w]indows", mode = { "n", "v" } },
            {
                "<leader>ww",
                function()
                    require("which-key").show({
                        keys = "<leader>w",
                        loop = true,
                    })
                end,
                desc = "Enter Hydra mode",
                mode = { "n", "v" },
            },
        },
    },
}
