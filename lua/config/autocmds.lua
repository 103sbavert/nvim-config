-- [[ Auto-commands ]]
-- Basic auto-cmds for QoL improvements

local close_hidden_buf_grp =
    vim.api.nvim_create_augroup("WipeUnnamedBuf", { clear = true })

-- Remove unnamed buf (such as the empty buffer created when Neovim is
-- first opened) when they are hidden if:
--  1. the buffer is not modified
--  2. the buffer type is an empty string (is a file buffer)
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

-- Below aucmds are inspired from LazyNvim

-- Closes certain buffers on 'q' press if file type matches
--
-- See `:help FileType`
local close_with_q_group =
    vim.api.nvim_create_augroup("close_with_q", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = close_with_q_group,
    pattern = {
        "PlenaryTestPopup",
        "checkhealth",
        "dap-float",
        "gitcommit",
        "gitsigns-blame",
        "help",
        "lspinfo",
        "notify",
        "qf",
        "startuptime",
        "tsplayground",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false

        vim.schedule(function()
            vim.keymap.set("n", "q", function()
                vim.cmd("close")
                pcall(vim.api.nvim_buf_delete, event.buf, {})
            end, {
                buffer = event.buf,
                silent = true,
                desc = "Quit",
            })
        end)
    end,
})

-- Sync disk modifications
local checktime_group =
    vim.api.nvim_create_augroup("ChecktimeGroup", { clear = true })

local function checktime()
    if vim.bo.buftype == "nofile" then
        return
    end
    if vim.fn.getcmdwintype() ~= "" then
        return
    end

    vim.cmd("checktime")
end

-- Refresh on focus shifts and terminal exits
vim.api.nvim_create_autocmd(
    { "FocusGained", "FocusLost", "TermClose", "TermLeave" },
    {
        group = checktime_group,
        callback = checktime,
    }
)

-- Refresh after closing git commit messages or git rebase todo buffers
vim.api.nvim_create_autocmd("FileType", {
    group = checktime_group,
    pattern = { "gitcommit", "gitrebase" },
    callback = function(event)
        vim.api.nvim_create_autocmd("BufUnload", {
            buffer = event.buf,
            once = true,
            callback = checktime,
        })
    end,
})
