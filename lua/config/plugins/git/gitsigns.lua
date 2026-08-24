--- @type LazySpec
return {
    "lewis6991/gitsigns.nvim",
    event = { "VeryLazy" },
    --- @type Gitsigns.Config
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

            --- @type Gitsigns.NavOpts
            --- @diagnostic disable-next-line: missing-fields
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
                utils.git_key_mapper(" ", function()
                    local range = { vim.fn.line("."), vim.fn.line("v") }
                    gitsigns.stage_hunk(range, { greedy = false })
                end, "[ ] stage/unstage hunk", nil, { "v" })

                utils.git_key_mapper(
                    " ",
                    gitsigns.stage_hunk,
                    "[ ] stage/unstage hunk",
                    nil,
                    { "n" }
                )

                utils.git_key_mapper(
                    "s",
                    gitsigns.stage_buffer,
                    "[s]tage buffer",
                    nil,
                    { "n" }
                )

                utils.git_key_mapper(
                    "u",
                    gitsigns.reset_buffer_index,
                    "[u]nstage buffer",
                    nil,
                    { "n" }
                )
            end

            -- History
            do
                utils.git_key_mapper(
                    "b",
                    function() gitsigns.blame({ ignore_whitespace = false }) end,
                    "[b]lame buffer"
                )
                utils.git_key_mapper(
                    "i",
                    function() gitsigns.blame_line({ full = true }) end,
                    "blame [i]nline"
                )
                utils.git_key_mapper(
                    "p",
                    gitsigns.preview_hunk,
                    "[p]review hunk"
                )
                utils.git_key_mapper(
                    "D",
                    function() utils.pick_diff_base(gitsigns.diffthis) end,
                    "View [D]iff against thing"
                )
            end

            -- Resets
            do
                utils.git_key_mapper(
                    "r",
                    gitsigns.reset_hunk,
                    "[r]eset cursor hunk",
                    nil,
                    { "n" }
                )
                utils.git_key_mapper(
                    "R",
                    gitsigns.reset_buffer,
                    "[R]eset buffer"
                )
                utils.git_key_mapper("r", function()
                    local range = { vim.fn.line("."), vim.fn.line("v") }
                    gitsigns.reset_hunk(range, { greedy = false })
                end, "[r]eset visual selection", nil, { "v" })
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
