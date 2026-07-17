local utils = require("config.plugins.chezmoi.utils")

local open_src_grp = vim.api.nvim_create_augroup("open_czm_src", {
    clear = true,
})

local apply_src_grp = vim.api.nvim_create_augroup("apply_czm_src", {
    clear = true,
})

local no_open_src_files = false
local no_apply_src_files = {}
local watched_src_files = {}

vim.api.nvim_create_autocmd("BufReadPost", {
    group = open_src_grp,
    callback = function(args)
        if no_open_src_files then
            return
        end

        local buf_id = args.buf
        if not vim.api.nvim_buf_is_valid(buf_id) then
            return
        end

        local buf_type = vim.bo[buf_id].filetype
        if not buf_type or buf_type == "" then
            return
        end

        local buf_file = vim.api.nvim_buf_get_name(buf_id)
        if buf_file == "" then
            return
        end

        utils.is_src_file(buf_file, function(is_src)
            if is_src then
                return
            end

            utils.get_src_file(buf_file, function(sources)
                if not sources or #sources == 0 then
                    return
                end

                local source = sources[1]

                utils.should_ignore_src_file(source, function(should_ignore)
                    if should_ignore then
                        return
                    end

                    if not source or not vim.uv.fs_stat(source) or source == buf_file then
                        return
                    end

                    if utils.has_symlink_attr(source) then
                        return
                    end

                    utils.ask_open_src_file(function(choice)
                            if choice == 2 then
                                utils.edit_chezmoi(buf_file)
                            elseif choice == 3 then
                                no_open_src_files = true
                            end
                    end)
                end)
            end)
        end)
    end,
})

utils.get_src_dir(function(src_dir)
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = apply_src_grp,
        pattern = vim.fs.joinpath(src_dir, "*"),
        callback = function(args)
            local buf_id = args.buf
            if not vim.api.nvim_buf_is_valid(buf_id) then
                return
            end

            local buf_type = vim.bo[buf_id].filetype
            if not buf_type or buf_type == "" then
                return
            end

            local buf_file = vim.api.nvim_buf_get_name(buf_id)
            if buf_file == "" then
                return
            end

            if no_apply_src_files[buf_file] then
                return
            end

            utils.should_ignore_src_file(buf_file, function(should_ignore)
                if should_ignore then
                    return
                end

                utils.is_src_file(buf_file, function(is_src)
                    if not is_src then
                        return
                    end

                    if watched_src_files[buf_file] then
                        utils.apply_chezmoi(buf_file)
                        return
                    end

                    utils.ask_apply_src_file(function(choice)
                        if choice == 2 or choice == 4 then
                            utils.apply_chezmoi(buf_file)
                        end

                        if choice == 3 then
                            no_apply_src_files[buf_file] = true
                        elseif choice == 4 then
                            watched_src_files[buf_file] = true
                            vim.notify("File will be auto-applied on save", vim.log.levels.INFO, { title = "Chezmoi" })
                        end
                    end)
                end)
            end)
        end,
    })
end)

vim.api.nvim_create_autocmd({ "BufDelete", "BufFilePre" }, {
    group = apply_src_grp,
    callback = function(args)
        local buf_file = vim.api.nvim_buf_get_name(args.buf)

        no_apply_src_files[buf_file] = nil
        watched_src_files[buf_file] = nil
    end,
})
