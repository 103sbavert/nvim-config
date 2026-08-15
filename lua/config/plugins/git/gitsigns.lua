---@type LazySpec
return {
    "lewis6991/gitsigns.nvim",
    event = { "VeryLazy" },
    opts = {
        signs = {
            add = { text = "+" },
            change = { text = "~" },
            delete = { text = "⎼" },
            topdelete = { text = "⎺" },
            changedelete = { text = "~" },
            untracked = { text = "⋮" },
        },
        attach_to_untracked = true,
        on_attach = function(bufnr)
            local gitsigns = require("gitsigns")
            local utils = require("config.plugins.git.utils")

            ---@type Gitsigns.NavOpts
            ---@diagnostic disable-next-line: missing-fields
            local navopts = { foldopen = true, target = "all", wrap = true }

            -- Navigation
            do
                utils.navigate_fw_mapper("c", function()
                    if vim.wo.diff then
                        return "]c"
                    end
                    vim.schedule(
                        function() gitsigns.nav_hunk("next", navopts) end
                    )
                    return "<Ignore>"
                end, "Jump to next git [c]hange")

                utils.navigate_bw_mapper("c", function()
                    if vim.wo.diff then
                        return "[c"
                    end
                    vim.schedule(
                        function() gitsigns.nav_hunk("prev", navopts) end
                    )
                    return "<Ignore>"
                end, "Jump to previous git [c]hange")
            end

            -- Staging
            do
                -- hunk
                utils.git_key_mapper(
                    " ",
                    function()
                        gitsigns.stage_hunk({
                            vim.fn.line("."),
                            vim.fn.line("v"),
                        })
                    end,
                    "[ ] toggle hunk staging",
                    nil,
                    { "v" }
                )
                utils.git_key_mapper(
                    " ",
                    gitsigns.stage_hunk,
                    "[ ] toggle hunk staging",
                    nil,
                    { "n" }
                )

                utils.git_key_mapper(
                    "s",
                    gitsigns.stage_buffer,
                    "[s]tage buffer"
                )
                utils.git_key_mapper(
                    "u",
                    gitsigns.reset_buffer_index,
                    "[u]nstage buffer"
                )
            end

            -- History
            do
                utils.git_key_mapper(
                    "b",
                    function() gitsigns.blame_line({ full = true }) end,
                    "[b]lame line"
                )
                utils.git_key_mapper(
                    "p",
                    gitsigns.preview_hunk,
                    "[p]review current hunk"
                )
                utils.git_key_mapper(
                    "D",
                    function() utils.pick_ref(gitsigns.diffthis) end,
                    "View [D]iff against ref"
                )
            end

            -- Resets
            do
                utils.git_reset_mapper(
                    "h",
                    gitsigns.reset_hunk,
                    "Reset [h]unk changes",
                    nil,
                    { "n" }
                )
                utils.git_reset_mapper(
                    "b",
                    gitsigns.reset_buffer,
                    "Reset [b]uffer changes"
                )
                utils.git_reset_mapper(
                    "h",
                    function()
                        gitsigns.reset_hunk({
                            vim.fn.line("."),
                            vim.fn.line("v"),
                        })
                    end,
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

            -- Commit
            do
                utils.git_key_mapper(
                    "c",
                    utils.commit,
                    "[c]ommit staged changes",
                    nil,
                    { "n" }
                )
            end

            -- Toggles
            do
                map_toggle_key(
                    "b",
                    gitsigns.toggle_current_line_blame,
                    "Current line [b]lame"
                )
            end
        end,
    },
}
