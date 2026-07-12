-- Add indentation guides even on blank lines
-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`

return {
    "lukas-reineke/indent-blankline.nvim",
    config = function() require("ibl").setup({}) end,
}
