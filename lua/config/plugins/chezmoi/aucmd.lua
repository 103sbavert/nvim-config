local UT = require("config.utils")
local UI = require("config.plugins.chezmoi.ui")
local shared = require("config.plugins.chezmoi.utils")
local state = require("config.plugins.chezmoi.state")
local actions = require("config.plugins.chezmoi.actions")

local chezmoi_apply_grp = vim.api.nvim_create_augroup("apply_czm_src", {
    clear = true,
})

--- Decides what to do with a saved source file.
--- @param file string
local function prompt_apply(file)
    if state.is_watched(file) then
        actions.apply(file, { quiet = true, is_src = true })
        return
    end

    UI.ask_apply(function(choice)
        if choice == UI.CHOICE.yes or choice == UI.CHOICE.watch then
            actions.apply(file, { is_src = true })
        end

        if choice == UI.CHOICE.never then
            state.mute(file)
        elseif choice == UI.CHOICE.watch then
            state.watch(file)
            UI.notify_ok("File will be auto-applied on save")
        end
    end)
end

local function chezmoi_apply_aucmd_cb(args)
    local buf_file = UT.get_current_file(args)

    if not buf_file or state.is_muted(buf_file) then
        return
    end

    -- Warm by construction: this autocmd is only registered from inside
    -- get_src_dir_async's callback below.
    local src_dir = shared.get_cached_src_dir()
    if not src_dir then
        return
    end

    state.track_buf(args.buf, buf_file)

    local progress = UT.progress("Checking file...", { title = "Chezmoi" })

    shared.classify_async(buf_file, { src_dir = src_dir }, function(class)
        progress:finish()

        if not class.is_src or class.ignored then
            return
        end

        -- vim.fn.confirm cannot run in a fast-event context.
        vim.schedule(function() prompt_apply(buf_file) end)
    end)
end

shared.get_src_dir_async(
    function(src_dir)
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = chezmoi_apply_grp,
            pattern = vim.fs.joinpath(src_dir, "*"),
            callback = chezmoi_apply_aucmd_cb,
        })
    end
)

-- local chezmoi_edit_grp = vim.api.nvim_create_augroup("open_czm_src", {
--     clear = true,
-- })
--
-- local no_open_src_files = false
--
-- local function chezmoi_edit_aucmd_cb(args)
--     if no_open_src_files then
--         return
--     end
--
--     local buf_file = UT.get_current_file(args)
--     local progress = UT.progress("Checking file...", { title = "Chezmoi" })
--
--     shared.is_src_file_async(buf_file, function(is_src)
--         if is_src then
--             progress:finish()
--             return
--         end
--
--         progress:step("Looking up source file...")
--         shared.get_src_file_async(buf_file, function(src_files)
--             local src = src_files and src_files[1]
--
--             if not src or src == buf_file then
--                 progress:finish()
--                 return
--             end
--
--             progress:step("Checking ignore rules...")
--             shared.classify_async(src, nil, function(class)
--                 if class.ignored or not vim.uv.fs_stat(src) then
--                     progress:finish()
--                     return
--                 end
--
--                 if shared.has_symlink_attr(src) then
--                     progress:finish()
--                     return
--                 end
--
--                 progress:finish()
--
--                 -- vim.fn.confirm cannot run in a fast-event context.
--                 vim.schedule(function()
--                     UI.ask_open(function(choice)
--                         if choice == UI.CHOICE.yes then
--                             shared.populate_ft_cache(vim.bo[args.buf].filetype, src)
--                             vim.cmd.tabedit(src)
--                         elseif choice == UI.CHOICE.never then
--                             no_open_src_files = true
--                         end
--                     end)
--                 end)
--             end)
--         end)
--     end)
-- end
--
-- vim.api.nvim_create_autocmd("BufReadPost", {
--     group = chezmoi_edit_grp,
--     callback = chezmoi_edit_aucmd_cb,
-- })
