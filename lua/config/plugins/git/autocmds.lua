local hide_blame_grp =
    vim.api.nvim_create_augroup("GitBlameHideGroup", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitsigns-blame",
    group = hide_blame_grp,
    callback = function(ev)
        vim.keymap.set("n", "q", "<CMD>q<CR>", {
            buf = ev.buf,
            desc = "Hide git blame",
        })
    end,
})
