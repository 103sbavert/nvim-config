--- @type LazySpec
return {
    "lewis6991/gitsigns.nvim",
    event = { "VeryLazy" },
    --- @type Gitsigns.Config
    opts = {
        diff_opts = {
            linematch = 60,
        },
        signs = {
            add = { text = "┆" },
            change = { text = "┆" },
            changedelete = { text = "¦̶" },
            delete = { text = "┄" },
            topdelete = { text = "﹉" },
            untracked = { text = "⋮" },
        },
        signs_staged = {
            add = { text = "┃" },
            change = { text = "┃" },
            changedelete = { text = "┣" },
            delete = { text = "━" },
            topdelete = { text = "▔" },
        },
        attach_to_untracked = true,
        on_attach = function(bufnr)
            local gitsigns = require("gitsigns")
            local utils = require("plugins.git.utils")

            --- Buffer-local git keymap under "<leader>g".
            --- @param keys string Key suffix appended to "<leader>g".
            --- @param rhs string|fun() Right-hand side of the mapping.
            --- @param desc string Keymap description.
            --- @param modes string|string[]? Defaults to "n".
            local function map_git(keys, rhs, desc, modes)
                vim.keymap.set(modes or "n", "<leader>g" .. keys, rhs, {
                    buffer = bufnr,
                    desc = desc,
                })
            end

            -- Navigation
            do
                vim.keymap.set(
                    { "n", "v" },
                    "]g",
                    utils.nav_hunk("next"),
                    { buffer = bufnr, expr = true, desc = "Next hunk" }
                )

                vim.keymap.set(
                    { "n", "v" },
                    "[g",
                    utils.nav_hunk("prev"),
                    { buffer = bufnr, expr = true, desc = "Previous hunk" }
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
                map_git("h", visual_hunk_stage, "[h]unk staging (toggle)", "v")

                local function normal_hunk_stage()
                    local locbufnr = vim.api.nvim_get_current_buf()
                    if not utils.ask_save_stage(locbufnr) then
                        return
                    end

                    gitsigns.stage_hunk()
                end

                map_git("h", normal_hunk_stage, "[h]unk staging (toggle)")

                map_git("s", function()
                    local locbufnr = vim.api.nvim_get_current_buf()
                    if not utils.ask_save_stage(locbufnr) then
                        return
                    end

                    gitsigns.stage_buffer()
                end, "[s]tage buffer")

                map_git("u", function()
                    local locbufnr = vim.api.nvim_get_current_buf()
                    if not utils.ask_save_stage(locbufnr) then
                        return
                    end

                    gitsigns.reset_buffer_index()
                end, "[u]nstage buffer")
            end

            -- History
            do
                map_git(
                    "b",
                    function() gitsigns.blame({ ignore_whitespace = false }) end,
                    "[b]lame buffer"
                )

                map_git(
                    "i",
                    function() gitsigns.blame_line({ full = true }) end,
                    "blame [i]nline"
                )

                map_git("p", gitsigns.preview_hunk, "[p]review hunk")
            end

            -- Resets
            do
                map_git("r", function()
                    local locbufnr = vim.api.nvim_get_current_buf()
                    utils.ask_reset_save(
                        locbufnr,
                        function(done) gitsigns.reset_hunk(nil, nil, done) end
                    )
                end, "[r]eset cursor hunk")

                map_git("R", function()
                    local locbufnr = vim.api.nvim_get_current_buf()
                    utils.ask_reset_save(locbufnr, function(done)
                        gitsigns.reset_buffer()
                        done()
                    end)
                end, "[R]eset buffer")

                map_git("r", function()
                    local s, e = vim.fn.line("."), vim.fn.line("v")
                    if s > e then
                        s, e = e, s
                    end
                    local range = { s, e }
                    local locbufnr = vim.api.nvim_get_current_buf()
                    utils.ask_reset_save(
                        locbufnr,
                        function(done)
                            gitsigns.reset_hunk(range, { greedy = false }, done)
                        end
                    )
                end, "[r]eset selection", "v")
            end

            -- Text object
            do
                vim.keymap.set(
                    { "o", "x" },
                    "ag",
                    function() utils.select_hunk(true) end,
                    { buffer = bufnr, desc = "[g]it hunk" }
                )

                vim.keymap.set(
                    { "o", "x" },
                    "ig",
                    function() utils.select_hunk(false) end,
                    { buffer = bufnr, desc = "[g]it hunk" }
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
