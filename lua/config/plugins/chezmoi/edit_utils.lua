local M = {}

local UT = require("config.utils")
local get_cmd_src_path = UT.lazy_require("nvim-chezmoi.chezmoi.commands.source_path")

local uv = vim.uv or vim.loop
local shared = require("config.plugins.chezmoi.utils")

--- Async check if path is inside dir.
--- @param path string?
--- @param dir string?
--- @param callback fun(is_path_inside_dir: boolean)
function M.is_path_inside_dir_async(path, dir, callback)
    local path_abs = shared.get_clean_absolute_path(path)
    local dir_abs = shared.get_clean_absolute_path(dir)

    if not path_abs or not dir_abs then
        callback(false)
        return
    end

    if not vim.endswith(dir_abs, "/") then
        dir_abs = dir_abs .. "/"
    end

    uv.fs_stat(path_abs, function(err, stat)
        if err or not stat then
            callback(false)
            return
        end

        local is_inside = path_abs:find(dir_abs, 1, true) == 1
        callback(is_inside)
    end)
end

--- Async check if file is a chezmoi source file.
--- @param file string?
--- @param callback fun(is_src: boolean)
function M.is_src_file_async(file, callback)
    shared.get_src_dir_async(function(src_dir)
        if not src_dir then
            callback(false)
            return
        end
        M.is_path_inside_dir_async(file, src_dir, callback)
    end)
end

--- Async resolve target file to its chezmoi source counterpart(s).
--- @param file string?
--- @param callback fun(src_files: string[]?)
function M.get_src_file_async(file, callback)
    local args = {}
    if file and file ~= "" then
        table.insert(args, file)
    end

    get_cmd_src_path():async(args, function(result)
        if not result.success or not result.data or #result.data == 0 then
            callback(nil)
            return
        end

        local abs_paths = {}
        for _, src in ipairs(result.data) do
            local abs = shared.get_clean_absolute_path(src)
            if abs then
                table.insert(abs_paths, abs)
            end
        end

        callback(#abs_paths > 0 and abs_paths or nil)
    end)
end

--- Async check if source file should be ignored.
--- @param file string?
--- @param callback fun(should_ignore: boolean)
function M.should_ignore_src_file_async(file, callback)
    if not file or file == "" then
        callback(false)
        return
    end

    shared.get_src_dir_async(function(src_dir)
        if not src_dir then
            callback(false)
            return
        end

        M.is_path_inside_dir_async(file, src_dir, function(is_inside)
            if not is_inside then
                callback(false)
                return
            end

            local rel_path = vim.fs.relpath(src_dir, file)
            if not rel_path or rel_path == "" then
                callback(false)
                return
            end

            local normal_rel_path = vim.fs.normalize(rel_path)
            if UT.has_hidden_component(normal_rel_path) then
                callback(true)
                return
            end

            for _, pattern in ipairs(shared.ignore_patterns) do
                if normal_rel_path:match(pattern) then
                    callback(true)
                    return
                end
            end

            callback(false)
        end)
    end)
end

--- Prompts to open chezmoi source file instead of target.
--- @param callback fun(choice: integer) 1 = No, 2 = Yes, 3 = Don't ask again, 0 = dismissed
function M.ask_open_src_file(callback)
    callback(
        vim.fn.confirm(
            "Open the chezmoi source file instead?\n",
            "&no" .. "\n&yes" .. "\n&don't ask again",
            1,
            "Question"
        )
    )
end

return M
