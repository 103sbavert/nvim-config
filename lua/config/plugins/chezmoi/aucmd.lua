local shared = require("config.plugins.chezmoi.utils")
local edit_utils = require("config.plugins.chezmoi.edit_utils")
local apply_utils = require("config.plugins.chezmoi.apply_utils")
local UT = require("config.utils")

local chezmoi_edit_grp = vim.api.nvim_create_augroup("open_czm_src", {
    clear = true,
})

local chezmoi_apply_grp = vim.api.nvim_create_augroup("apply_czm_src", {
    clear = true,
})

local no_open_src_files = false
local no_apply_src_files = {}
local watched_src_files = {}

local function chezmoi_edit_aucmd_cb(args)
    vim.g.initial_trigger_done = true
    if no_open_src_files then
        return
    end

    local buf_file = UT.get_current_file(args)
    local handle = require("fidget.progress").handle.create({
        title = "Chezmoi",
        message = "Checking file...",
        lsp_client = { name = "chezmoi" },
        cancellable = false,
    })

    edit_utils.is_src_file_async(buf_file, function(is_src)
        if is_src then
            handle:finish()
            return
        end

        handle.message = "Looking up source file..."
        edit_utils.get_src_file_async(buf_file, function(src_files)
            if not src_files or #src_files == 0 then
                handle:finish()
                return
            end

            local src = src_files[1]

            handle.message = "Checking ignore rules..."
            edit_utils.should_ignore_src_file_async(src, function(should_ignore)
                if should_ignore then
                    handle:finish()
                    return
                end

                if not src or not vim.uv.fs_stat(src) or src == buf_file then
                    handle:finish()
                    return
                end

                if shared.has_symlink_attr(src) then
                    handle:finish()
                    return
                end

                handle:finish()

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
end

local function clear_state_on_delete(buf_id, buf_file)
    if not buf_id or not buf_file then
        return
    end

    vim.api.nvim_create_autocmd({ "BufDelete", "BufFilePre" }, {
        buf = buf_id,
        once = true,
        group = chezmoi_apply_grp,
        callback = function()
            no_apply_src_files[buf_file] = nil
            watched_src_files[buf_file] = nil
        end,
    })
end

local function chezmoi_apply_aucmd_cb(args)
    local buf_id = args.buf or 0
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
        apply_utils.apply_chezmoi_async(buf_file, { quiet = true })
        return
    end

    apply_utils.ask_apply_src_file(function(choice)
        if choice == 2 or choice == 4 then
            apply_utils.apply_chezmoi_async(buf_file, nil)
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

    clear_state_on_delete(buf_id, buf_file)
end

vim.api.nvim_create_autocmd("BufReadPost", {
    group = chezmoi_edit_grp,
    callback = chezmoi_edit_aucmd_cb,
})

shared.get_src_dir_async(
    function(src_dir)
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = chezmoi_apply_grp,
            pattern = vim.fs.joinpath(src_dir, "*"),
            callback = chezmoi_apply_aucmd_cb,
        })
    end
)

return {
    chezmoi_edit_autocmd_cb = chezmoi_edit_aucmd_cb,
    chezmoi_apply_autocmd_cb = chezmoi_apply_aucmd_cb,
}
