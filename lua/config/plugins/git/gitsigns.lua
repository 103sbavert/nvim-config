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
                utils.navigate_fw_mapper(
                    "c",
                    function()
                        if vim.wo.diff then
                            return "]c"
                        end
                        vim.schedule(
                            function() gitsigns.nav_hunk("next", navopts) end
                        )
                        return "<Ignore>"
                    end,
                    "Jump to next git [c]hange",
                    {
                        buffer = bufnr,
                        expr = true,
                    }
                )

                utils.navigate_bw_mapper(
                    "c",
                    function()
                        if vim.wo.diff then
                            return "[c"
                        end
                        vim.schedule(
                            function() gitsigns.nav_hunk("prev", navopts) end
                        )
                        return "<Ignore>"
                    end,
                    "Jump to previous git [c]hange",
                    {
                        buffer = bufnr,
                        expr = true,
                    }
                )
            end

            -- Staging
            do
                local function visual_hunk_stage()
                    local s, e = vim.fn.line("."), vim.fn.line("v")
                    if s > e then
                        s, e = e, s
                    end
                    local range = { s, e }
                    local locbufnr = vim.api.nvim_get_current_buf()
                    if not utils.ask_save_stage(locbufnr) then
                        return
                    end

                    gitsigns.stage_hunk(range, { greedy = false })
                end

                -- hunk
                utils.git_key_mapper(
                    "<space>",
                    visual_hunk_stage,
                    "[ ] stage/unstage hunk",
                    { buffer = bufnr },
                    { "v" }
                )

                local function normal_hunk_stage()
                    local locbufnr = vim.api.nvim_get_current_buf()
                    if not utils.ask_save_stage(locbufnr) then
                        return
                    end

                    gitsigns.stage_hunk()
                end

                utils.git_key_mapper(
                    "<space>",
                    normal_hunk_stage,
                    "[ ] stage/unstage hunk",
                    { buffer = bufnr },
                    { "n" }
                )

                utils.git_key_mapper(
                    "s",
                    function()
                        local locbufnr = vim.api.nvim_get_current_buf()
                        if not utils.ask_save_stage(locbufnr) then
                            return
                        end

                        utils.toggle_buf_staging(locbufnr)
                    end,
                    "Toggle file [s]taging",
                    { buffer = bufnr },
                    {
                        "n",
                    }
                )
            end

            -- History
            do
                utils.git_key_mapper(
                    "b",
                    function() gitsigns.blame({ ignore_whitespace = false }) end,
                    "[b]lame buffer",
                    { buffer = bufnr },
                    { "n" }
                )
                utils.git_key_mapper(
                    "i",
                    function() gitsigns.blame_line({ full = true }) end,
                    "blame [i]nline",
                    { buffer = bufnr },
                    { "n" }
                )
                utils.git_key_mapper(
                    "p",
                    gitsigns.preview_hunk,
                    "[p]review hunk",
                    { buffer = bufnr },
                    { "n" }
                )
            end

            -- Resets
            do
                utils.git_key_mapper(
                    "r",
                    function()
                        local locbufnr = vim.api.nvim_get_current_buf()
                        utils.ask_reset_save(
                            locbufnr,
                            function(done) gitsigns.reset_hunk(nil, nil, done) end
                        )
                    end,
                    "[r]eset cursor hunk",
                    { buffer = bufnr },
                    {
                        "n",
                    }
                )

                utils.git_key_mapper(
                    "R",
                    function()
                        local locbufnr = vim.api.nvim_get_current_buf()
                        utils.ask_reset_save(locbufnr, function(done)
                            gitsigns.reset_buffer()
                            done()
                        end)
                    end,
                    "[R]eset buffer",
                    { buffer = bufnr },
                    {
                        "n",
                    }
                )

                utils.git_key_mapper(
                    "r",
                    function()
                        local s, e = vim.fn.line("."), vim.fn.line("v")
                        if s > e then
                            s, e = e, s
                        end
                        local range = { s, e }
                        local locbufnr = vim.api.nvim_get_current_buf()
                        utils.ask_reset_save(
                            locbufnr,
                            function(done)
                                gitsigns.reset_hunk(
                                    range,
                                    { greedy = false },
                                    done
                                )
                            end
                        )
                    end,
                    "[r]eset selection",
                    { buffer = bufnr },
                    {
                        "v",
                    }
                )
            end

            -- Text object
            do
                vim.keymap.set(
                    { "o", "x" },
                    "ih",
                    gitsigns.select_hunk,
                    { buffer = bufnr, desc = "Select hunk" }
                )
            end

            -- Toggles
            do
                map_toggle_key(
                    "b",
                    gitsigns.toggle_current_line_blame,
                    "Current line [b]lame",
                    { buffer = bufnr }
                )
            end
        end,
    },
}
