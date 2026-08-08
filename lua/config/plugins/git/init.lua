---@type LazySpec
return {
    "lewis6991/gitsigns.nvim",
    dependencies = { "kdheepak/lazygit.nvim" },
    event = { "VeryLazy" },
    opts = {
        signs = {
            add = { text = "+" },
            change = { text = "~" },
            delete = { text = "⎽" },
            topdelete = { text = "⎺" },
            changedelete = { text = "~" },
            untracked = { text = "┇" },
        },
        attach_to_untracked = true,
        on_attach = function(bufnr)
            local gitsigns = require("gitsigns")
            local utils = require("config.plugins.git.utils")

            ---@type Gitsigns.NavOpts
            ---@diagnostic disable-next-line: missing-fields
            local navopts = { foldopen = true, target = "all", wrap = true }

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
                    vim.schedule(function() gitsigns.nav_hunk("next", navopts) end)
                    return "<Ignore>"
                end, "Jump to next git [c]hange")

                navigate_bw_mapper("c", function()
                    if vim.wo.diff then
                        return "[c"
                    end
                    vim.schedule(function() gitsigns.nav_hunk("prev", navopts) end)
                    return "<Ignore>"
                end, "Jump to previous git [c]hange")
            end

            -- Staging
            do
                -- hunk
                git_key_mapper(
                    " ",
                    function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
                    "[ ] toggle hunk staging",
                    nil,
                    { "v" }
                )
                git_key_mapper(" ", gitsigns.stage_hunk, "[ ] toggle hunk staging", nil, { "n" })

                git_key_mapper("s", gitsigns.stage_buffer, "[s]tage buffer")
                git_key_mapper("u", gitsigns.reset_buffer_index, "[u]nstage buffer")
            end

            -- History
            do
                git_key_mapper("b", function() gitsigns.blame_line({ full = true }) end, "[b]lame line")
                git_key_mapper("p", gitsigns.preview_hunk, "[p]review current hunk")
                git_key_mapper("D", function() utils.pick_ref(gitsigns.diffthis) end, "View [D]iff against ref")
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
                vim.g.lazygit_floating_window_scaling_factor = 0.80
                vim.g.lazygit_floating_window_use_plenary = 1
                vim.g.lazygit_use_neovim_remote = 0

                git_key_mapper("l", utils.open_lazy_git, "Open [l]azyGit")
            end

            -- Commit
            do
                git_key_mapper("c", utils.commit, "[c]ommit staged changes", nil, { "n" })
            end

            -- Toggles
            do
                map_toggle_key("b", gitsigns.toggle_current_line_blame, "Current line [b]lame")
            end
        end,
    },
}
