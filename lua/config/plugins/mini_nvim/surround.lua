require("mini.surround").setup({
    mappings = {
        add = "s", -- conflicts with builtin substitute; intended
        find = "s/",
        find_left = "s?",
        update_n_lines = "sn", -- no default mapping; custom
    },
})
