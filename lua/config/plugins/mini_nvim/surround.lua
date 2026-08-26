require("mini.surround").setup({
    mappings = {
        add = "s", -- Add surrounding around textobject (e.g., siw", saW")
        delete = "sd", -- Delete surrounding (e.g., sd")
        find = "s/", -- Find next surrounding to the right (e.g., s/")
        find_left = "s?", -- Find previous surrounding to the left (e.g., s?")
        highlight = "sh", -- Highlight surrounding (e.g., sh")
        replace = "sr", -- Replace surrounding pair (e.g., sr"')
        update_n_lines = "sn", -- Adjust max search line range for detecting surroundings
    },
})
