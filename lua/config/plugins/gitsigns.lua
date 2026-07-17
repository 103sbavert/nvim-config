return {
    "lewis6991/gitsigns.nvim",
    dependencies = { "kdheepak/lazygit.nvim" },
    event = { "VeryLazy" },
    config = function()
        require("gitsigns").setup({
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
                untracked = { text = "┆" },
            },
            attach_to_untracked = true,
            on_attach = function(bufnr)
                local gitsigns = require("gitsigns")

                -- Initialize mappers
                local git_key_mapper = create_keymap_group("[g]it", "<leader>g", { "n", "v" })
                local git_reset_mapper = create_keymap_group("[r]eset", "<leader>gr", { "n", "v" })
                local navigate_bw_mapper = create_keymap_group("[ backwards", "[", { "n", "v" })
                local navigate_fw_mapper = create_keymap_group("] forwards", "]", { "n", "v" })

                -- Navigation
                do
                    navigate_fw_mapper("c", function()
                        if vim.wo.diff then
                            return "]c"
                        end
                        vim.schedule(function() gitsigns.nav_hunk("next") end)
                        return "<Ignore>"
                    end, "Jump to next git [c]hange")

                    navigate_bw_mapper("c", function()
                        if vim.wo.diff then
                            return "[c"
                        end
                        vim.schedule(function() gitsigns.nav_hunk("prev") end)
                        return "<Ignore>"
                    end, "Jump to previous git [c]hange")
                end

                -- Staging
                do
                    git_key_mapper(
                        "h",
                        function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                        "Toggle [h]unk staging",
                        nil,
                        { "v" }
                    )
                    git_key_mapper("h", gitsigns.stage_hunk, "Toggle [h]unk staging", nil, { "n" })
                    git_key_mapper("s", gitsigns.stage_buffer, "[s]tage buffer")
                    git_key_mapper("u", gitsigns.reset_buffer_index, "[u]nstage buffer")
                end

                -- History
                do
                    git_key_mapper("b", function() gitsigns.blame_line({ full = true }) end, "[b]lame line")
                    git_key_mapper("d", gitsigns.diffthis, "View [d]iff against index")
                    git_key_mapper("D", function() gitsigns.diffthis("@") end, "View [D]iff against HEAD")
                end

                -- Resets
                do
                    git_reset_mapper("h", gitsigns.reset_hunk, "Reset [h]unk changes", nil, { "n" })
                    git_reset_mapper("b", gitsigns.reset_buffer, "Reset [b]uffer changes")
                    git_reset_mapper(
                        "h",
                        function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                        "Reset [h]unk changes",
                        nil,
                        { "v" }
                    )
                end

                -- Text object
                do
                    vim.keymap.set(
                        { "o", "x" },
                        "ih",
                        ":<C-U>Gitsigns select_hunk<CR>",
                        { buffer = bufnr, desc = "Select hunk" }
                    )
                end

                -- LazyGit
                do
                    git_key_mapper("g", "<cmd>LazyGitCurrentFile<cr>", "Initialize LazyGit TUI")
                end

                -- Toggles
                do
                    map_toggle_key("b", gitsigns.toggle_current_line_blame, "Current line [b]lame")
                end
            end,
        })
    end,
}
