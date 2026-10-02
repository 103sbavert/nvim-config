-- [[ Auto-commands ]]
-- Basic auto-cmds for QoL improvements
--
-- See `:help autocmd`
local close_win_q_grp =
    vim.api.nvim_create_augroup("CloseBufWithQ", { clear = true })

-- Closes certain buffers on 'q' press if file type matches
--
-- See `:help FileType`
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "gitsigns-blame", "gitcommit", "help" },
    group = close_win_q_grp,
    callback = function(ev)
        vim.keymap.set("n", "q", vim.cmd.quit, {
            buf = ev.buf,
            desc = "Close",
        })
    end,
})

local close_hidden_buf_grp =
    vim.api.nvim_create_augroup("WipeUnnamedBuf", { clear = true })

-- Remove unnamed buf (such as the empty buffer created when Neovim is
-- first opened) when they are hidden if:
--  1. the buffer is not modified buffer id
--  2. the buffer is still valid at the next tick
vim.api.nvim_create_autocmd("BufHidden", {
    group = close_hidden_buf_grp,
    callback = function(ev)
        local buf_id = ev.buf
        local buf_name = vim.api.nvim_buf_get_name(buf_id)

        -- Skip if has name
        if buf_name ~= "" then
            return
        end

        -- Skip non-normal buffers
        if vim.bo[buf_id].buftype ~= "" then
            return
        end

        -- Skip if modified
        if vim.bo[buf_id].modified then
            return
        end

        -- Delete on next tick after hidden event
        vim.schedule(function()
            -- Check if buffer ID is still valid at this moment
            if vim.api.nvim_buf_is_valid(buf_id) then
                -- Delete buffer
                vim.api.nvim_buf_delete(buf_id, {})
            end
        end)
    end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--
-- See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup(
        "kickstart-highlight-yank",
        { clear = true }
    ),
    callback = function() vim.hl.on_yank() end,
})
