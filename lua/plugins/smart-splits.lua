--- @type LazySpec
return {
    "smart-splits-nvim/smart-splits.nvim",
    lazy = false,
    dependencies = {
        { "smart-splits-nvim/backend-tmux" },
    },
    --- @type SmartSplitsSetupOpts
    opts = {
        ignored_filetypes = { "lazygit", "snacks_picker_list" },
        move = {
            same_row = true,
            at_edge = "stop",
        },
        swap = {
            move_cursor = true,
        },
        mux = {
            backend = "smart-splits-backend-tmux",
        },
    },

    config = function(_, opts)
        local ss = require("smart-splits")
        ss.setup(opts)

        local modes = { "n", "i", "t", "v" }

        local win_nav_dirs = {
            h = "left",
            j = "down",
            k = "up",
            l = "right",
        }

        local swap_keys = {
            left = "<M-S-h>",
            down = "<M-S-j>",
            up = "<M-S-k>",
            right = "<M-S-l>",
        }

        local function tmux_socket()
            if not vim.env.TMUX then
                return nil
            end

            return vim.split(vim.env.TMUX, ",", { plain = true })[1]
        end

        local tmux_swap_targets = {
            left = "{left-of}",
            down = "{bottom-of}",
            up = "{top-of}",
            right = "{right-of}",
        }

        local tmux_edges = {
            left = "pane_at_left",
            down = "pane_at_bottom",
            up = "pane_at_top",
            right = "pane_at_right",
        }

        local neovim_edges = {
            left = "h",
            down = "j",
            up = "k",
            right = "l",
        }

        local function swap_tmux_pane(direction)
            local socket = tmux_socket()
            if not socket then
                return
            end

            local edge = tmux_edges[direction]
            local target = tmux_swap_targets[direction]

            local edge_result = vim.system({
                "tmux",
                "-S",
                socket,
                "display-message",
                "-p",
                "-F",
                "#{" .. edge .. "}",
            }, {
                text = true,
                timeout = 300,
            }):wait()

            if edge_result.code ~= 0 then
                return
            end

            -- 1 means there is no pane in this direction.
            if vim.trim(edge_result.stdout or "") == "1" then
                return
            end

            vim.system({
                "tmux",
                "-S",
                socket,
                "swap-pane",
                "-d",
                "-t",
                target,
            }, {
                timeout = 300,
            }):wait()
        end

        local function neovim_at_edge(direction)
            local win_key = neovim_edges[direction]
            return vim.fn.winnr() == vim.fn.winnr(win_key)
        end

        for k, direction in pairs(win_nav_dirs) do
            -- C-h/j/k/l: move focus
            local move_key = "<C-" .. k .. ">"

            vim.keymap.set(modes, move_key, function()
                if vim.api.nvim_win_get_config(0).relative ~= "" then
                    vim.api.nvim_feedkeys(vim.keycode(move_key), "n", false)
                    return
                end

                ss["move_cursor_" .. direction]()
            end, {
                desc = "Window " .. direction,
            })

            -- C-S-h/j/k/l: resize
            local resize_key = "<C-S-" .. k .. ">"

            vim.keymap.set(
                modes,
                resize_key,
                ss["resize_" .. direction],
                { desc = "Resize split " .. direction }
            )

            -- M-S-Arrow: swap buffers or tmux panes
            local swap_key = swap_keys[direction]

            vim.keymap.set(modes, swap_key, function()
                if vim.api.nvim_win_get_config(0).relative ~= "" then
                    ss["swap_buf_" .. direction]()
                    return
                end

                if neovim_at_edge(direction) then
                    swap_tmux_pane(direction)
                else
                    ss["swap_buf_" .. direction]()
                end
            end, {
                desc = "Swap " .. direction,
            })
        end
    end,
}
