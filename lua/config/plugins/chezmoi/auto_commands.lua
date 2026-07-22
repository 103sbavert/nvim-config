local shared = require("config.plugins.chezmoi.utils")
local edit_utils = require("config.plugins.chezmoi.edit_utils")
local apply_utils = require("config.plugins.chezmoi.apply_utils")
local UT = require("config.utils")

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

        local buf_file = UT.get_current_file(args)

        edit_utils.is_src_file_async(buf_file, function(is_src)
            if is_src then
                return
            end

            edit_utils.get_src_file_async(buf_file, function(src_files)
                if not src_files or #src_files == 0 then
                    return
                end

                local src = src_files[1]

                edit_utils.should_ignore_src_file_async(src, function(should_ignore)
                    if should_ignore then
                        return
                    end

                    if not src or not vim.uv.fs_stat(src) or src == buf_file then
                        return
                    end

                    if shared.has_symlink_attr(src) then
                        return
                    end

                    vim.schedule(function()
                        edit_utils.ask_open_src_file(function(choice)
                            if choice == 2 then
                                local buf_type = vim.bo[args.buf].filetype
                                shared.populate_ft_cache(buf_type, src)

                                vim.cmd.edit(src)
                            elseif choice == 3 then
                                no_open_src_files = true
                            end
                        end)
                    end)
                end)
            end)
        end)
    end,
})

shared.get_src_dir_async(function(src_dir)
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = apply_src_grp,
        pattern = vim.fs.joinpath(src_dir, "*"),
        callback = function(args)
            local buf_file = UT.get_current_file(args)

            if not buf_file then
                return
            end

            if no_apply_src_files[buf_file] then
                return
            end

            if apply_utils.should_ignore_src_file(buf_file) then
                return
            end

            if not apply_utils.is_src_file(buf_file) then
                return
            end

            if watched_src_files[buf_file] then
                apply_utils.apply_chezmoi(buf_file, { quiet = true })
                return
            end

            apply_utils.ask_apply_src_file(function(choice)
                if choice == 2 or choice == 4 then
                    apply_utils.apply_chezmoi(buf_file)
                end

                if choice == 3 then
                    no_apply_src_files[buf_file] = true
                elseif choice == 4 then
                    watched_src_files[buf_file] = true
                    vim.notify(
                        "File will be auto-applied on save",
                        vim.log.levels.INFO,
                        { title = "Chezmoi" }
                    )
                end
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
