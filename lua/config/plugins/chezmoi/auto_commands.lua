local utils = require("config.plugins.chezmoi.utils")

local open_src_grp = vim.api.nvim_create_augroup("open_czm_src", {
    clear = true,
})

local apply_src_grp = vim.api.nvim_create_augroup("apply_czm_src", {
    clear = true,
})
local no_apply_src_files = {}
local watched_src_files = {}

vim.api.nvim_create_autocmd("BufReadPre", {
    group = open_src_grp,
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
    group = apply_src_grp,
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

        if no_apply_src_files[buf_file] then
            return
        elseif watched_src_files[buf_file] then
            utils.apply_src_files(buf_file)
            return
        end

        local choice = utils.ask_apply_src_file()

        if choice == 2 or choice == 4 then
            utils.apply_src_files(buf_file)
            vim.notify("Applied to target", vim.log.levels.INFO, { title = "Chezmoi" })
        end

        if choice == 3 then
            no_apply_src_files[buf_file] = true
        elseif choice == 4 then
            watched_src_files[buf_file] = true
            vim.notify("File will be auto-applied on save", vim.log.levels.INFO, { title = "Chezmoi" })
        end
    end,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufFilePre" }, {
    group = apply_src_grp,
    callback = function(args)
        local buf_file = vim.api.nvim_buf_get_name(args.buf)
        no_apply_src_files[buf_file] = nil
        watched_src_files[buf_file] = nil
    end,
})
