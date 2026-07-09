local utils = require("custom.chezmoi.utils")

local group = vim.api.nvim_create_augroup("chezmoi_auto_cmd", {
    clear = true,
})

vim.api.nvim_create_autocmd("BufReadPre", {
    group = group,
    callback = function(args)
        local buf = args.buf

        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
                return
            end

            local buf_file = vim.api.nvim_buf_get_name(buf)
            if buf_file == "" or utils.is_src_file(buf_file) then
                return
            end

            local sources_tbl = utils.get_src_file(buf_file)

            if not sources_tbl or vim.tbl_isempty(sources_tbl) then
                return
            end

            local source = sources_tbl[1]

            if not source or not vim.uv.fs_lstat(source) or source == buf_file then
                return
            end

            if utils.has_symlink_attr(source) then
                return
            end

            if utils.ask_open_src_file() then
                utils.open_src_file(buf_file)
            end
        end)
    end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(args)
        local buf = args.buf
        if vim.bo[buf].buftype ~= "" then
            return
        end

        local buf_file = vim.api.nvim_buf_get_name(buf)
        if buf_file == "" or utils.should_ignore_src_file(buf_file) then
            return
        end

        if not utils.is_src_file(buf_file) then
            return
        end

        if utils.ask_apply_to_tgt() then
            utils.apply_src_files(buf_file)
            vim.notify("Applied to target", vim.log.levels.INFO, { title = "chezmoi.nvim" })
        end
    end,
})
