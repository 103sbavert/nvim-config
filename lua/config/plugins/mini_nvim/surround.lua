require("mini.surround").setup({
    mappings = {
        add = "s", -- Add surrounding around textobject (e.g., siw), saw", s$)
        delete = "sd", -- Delete surrounding (e.g., sd", sd()
        find = "sf", -- Find next surrounding to the right (e.g., sf")
        find_left = "sF", -- Find previous surrounding to the left (e.g., sF")
        highlight = "sh", -- Highlight surrounding (e.g., sh")
        replace = "sr", -- Replace surrounding pair (e.g., sr"')
        update_n_lines = "sn", -- Adjust max search line range for detecting surroundings
    },
})
