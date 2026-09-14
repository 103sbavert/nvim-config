--- @type LazySpec
return {
    "carderne/pi-nvim",
    config = true,
    cmd = { "Pi", "PiSend", "PiSendSelection", "PiSendBuffer" },
    keys = {
        { "<leader>pp", "<cmd>PiSend<cr>", mode = "n", desc = "Pi send" },
        {
            "<leader>pp",
            ":PiSendSelection<CR>",
            mode = "v",
            desc = "Pi send selection",
        },
        { "<leader>P", "<cmd>Pi<cr>", desc = "[P]i" },
        { "<leader>pb", "<cmd>PiSendBuffer<cr>", desc = "Send [b]uffer" },
    },
    --- @type pi_nvim.Config
    opts = {
        set_default_keymaps = false,
    },
}
