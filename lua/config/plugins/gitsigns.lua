return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require("gitsigns").setup({
            signs = {
                add = { text = "+" }, ---@diagnostic disable-line: missing-fields
                change = { text = "~" }, ---@diagnostic disable-line: missing-fields
                delete = { text = "_" }, ---@diagnostic disable-line: missing-fields
                topdelete = { text = "‾" }, ---@diagnostic disable-line: missing-fields
                changedelete = { text = "~" }, ---@diagnostic disable-line: missing-fields
            },
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                local git_key_mapper = create_keymap_group("[g]it", "<leader>g", { "n", "v" })
                local navigate_bw_mapper = create_keymap_group("[ backwards", "[", { "n", "v" })
                local navigate_fw_mapper = create_keymap_group("] forwards", "]", { "n", "v" })

                -- Navigation
                navigate_fw_mapper("c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gitsigns.nav_hunk("next")
                    end
                end, "Jump to next git [c]hange")

                navigate_bw_mapper("c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gitsigns.nav_hunk("prev")
                    end
                end, "Jump to previous git [c]hange")

                -- hunk staging - visual mode
                git_key_mapper(
                    "h",
                    function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                    "Stage [h]unk",
                    nil,
                    "v"
                )

                git_key_mapper(
                    "H",
                    function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                    "Unstage [H]unk",
                    nil,
                    "v"
                )

                -- hunk staging - normal mode
                git_key_mapper("h", gitsigns.stage_hunk, "Stage [h]unk")
                git_key_mapper("H", gitsigns.stage_hunk, "Unstage [H]unk")

                -- buffer staging - normal mode
                git_key_mapper("s", gitsigns.stage_buffer, "[s]tage buffer", nil, "n")
                git_key_mapper("u", gitsigns.reset_buffer, "[u]nstage buffer", nil, "n")

                -- history - diff and blame
                git_key_mapper("b", function() gitsigns.blame_line({ full = true }) end, "[b]lame line")
                map_toggle_key("b", gitsigns.toggle_current_line_blame, "Current line [b]lame")
                git_key_mapper("d", gitsigns.diffthis, "View [d]iff against index")
                git_key_mapper("D", function() gitsigns.diffthis("@") end, "View [D]iff against index")

                -- text object 'h'unk
                vim.keymap.set({ "o", "x" }, "ih", gitsigns.select_hunk, { buffer = bufnr })

                -- LazyGit TUI with kdheepak/lazygit.nvim
                git_key_mapper("g", "<cmd>LazyGitCurrentFile<cr>", "Initialize LazyGit TUI")
            end,
        })
    end,
}
