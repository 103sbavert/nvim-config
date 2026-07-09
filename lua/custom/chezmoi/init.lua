require("chezmoi").setup({
    edit = {
        watch = false,
        force = false,
        ignore_patterns = {
            "run_",
            "%.chezmoi",
            "%.gitignore",
            "%.git/",
            "%.[^%.%/]",
            "^%.[^%.%/]",
        },
    },
    events = {
        on_open = {
            notification = {
                enable = true,
                msg = "Opened a chezmoi-managed file",
                opts = {},
            },
        },
        on_watch = {
            notification = {
                enable = true,
                msg = "This file will be automatically applied",
                opts = {},
            },
        },
        on_apply = {
            notification = {
                enable = true,
                msg = "Successfully applied",
                opts = {},
            },
        },
    },
    telescope = {
        select = { "<CR>" },
    },
})

local register_chezmoi_keymap = create_keymap_group("Che[Z]moi", "<leader>z", { "n" })

require("custom.chezmoi.auto_commands")
require("custom.chezmoi.user_commands")

local mappings = {
    e = {
        function() vim.cmd("ChezmoiEdit") end,
        "[E]dit a chezmoi source file",
    },
    a = {
        function() vim.cmd("ChezmoiApply") end,
        "[A]pply chezmoi changes",
    },
    f = {
        function() require("telescope.pick").telescope() end,
        "Search chezmoi managed [F]iles",
    },
}

for key, def in pairs(mappings) do
    register_chezmoi_keymap(key, def[1], def[2])
end
