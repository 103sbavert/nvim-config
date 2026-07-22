local M = {}

local UT = require("config.utils")
local get_cmd_apply = UT.lazy_require("nvim-chezmoi.chezmoi.commands.apply")

local uv = vim.uv or vim.loop
local shared = require("config.plugins.chezmoi.utils")

--- Synchronous check if path is inside dir.
--- @param path string?
--- @param dir string?
--- @return boolean
function M.is_path_inside_dir(path, dir)
    local path_abs = shared.get_clean_absolute_path(path)
    local dir_abs = shared.get_clean_absolute_path(dir)

    if not path_abs or not dir_abs then
        return false
    end

    if not vim.endswith(dir_abs, "/") then
        dir_abs = dir_abs .. "/"
    end

    local stat = uv.fs_stat(path_abs)
    if not stat then
        return false
    end

    return path_abs:find(dir_abs, 1, true) == 1
end

--- Synchronous check if file is a chezmoi source file.
--- @param file string?
--- @return boolean
function M.is_src_file(file)
    local src_dir = shared.get_cached_src_dir()
    if not src_dir then
        return false
    end
    return M.is_path_inside_dir(file, src_dir)
end

--- Synchronous check if source file should be ignored.
--- @param file string?
--- @return boolean
function M.should_ignore_src_file(file)
    if not file or file == "" then
        return false
    end

    local src_dir = shared.get_cached_src_dir()
    if not src_dir then
        return false
    end

    if not M.is_path_inside_dir(file, src_dir) then
        return false
    end

    local rel_path = vim.fs.relpath(src_dir, file)
    if not rel_path or rel_path == "" then
        return false
    end

    local normal_rel_path = vim.fs.normalize(rel_path)
    if UT.has_hidden_component(normal_rel_path) then
        return true
    end

    for _, pattern in ipairs(shared.ignore_patterns) do
        if normal_rel_path:match(pattern) then
            return true
        end
    end

    return false
end

--- Synchronous chezmoi apply.
--- @param file string?
--- @param opts? { quiet: boolean }
function M.apply_chezmoi(file, opts)
    file = file or vim.api.nvim_buf_get_name(0)

    if not file or type(file) ~= "string" then
        vim.notify("Filenames must be string", vim.log.levels.ERROR, { title = "Chezmoi" })
        return
    end

    local args
    if M.is_src_file(file) then
        args = { "--source-path", file }
    else
        args = { file }
    end

    local res = get_cmd_apply():exec(args)

    if opts and opts.quiet then
        return
    end

    if not res or res.success then
        vim.notify("Applied changes to target", vim.log.levels.INFO, { title = "Chezmoi" })
    else
        local m = table.concat(res.data)
        vim.notify(m, vim.log.levels.ERROR, { title = "Chezmoi" })
    end
end

--- Prompts to apply chezmoi source file to target.
--- @param callback fun(choice: integer) 1 = No, 2 = Yes, 3 = Don't ask again, 4 = Watch, 0 = dismissed
function M.ask_apply_src_file(callback)
    callback(
        vim.fn.confirm(
            "Apply to the chezmoi target now?\n",
            "&no" .. "\n&yes" .. "\n&don't ask again" .. "\n&watch this file",
            1,
            "Question"
        )
    )
end

return M
