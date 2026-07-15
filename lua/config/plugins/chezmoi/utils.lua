local M = {}

local cmd_source_path = require("nvim-chezmoi.chezmoi.commands.source_path")
local cmd_target_path = require("nvim-chezmoi.chezmoi.commands.target_path")
local uv = vim.uv or vim.loop

local cached_src_dir = nil

--- Lua patterns matched against relative source paths. Matching files are skipped.
--- @type string[]
local ignore_patterns = {
    "run_",
    "%.chezmoi",
    "%.gitignore",
    "%.git/",
    "(^|/).[^/.]",
}

--- Safely resolves and normalizes an arbitrary path into a clean absolute system location.
--- @param p string? The filesystem path to normalize.
--- @return string? The absolute, normalized path, or nil if input is invalid.
local function get_clean_absolute_path(p)
    if not p or p == "" then
        return nil
    end

    return vim.fs.abspath(p)
end

--- Determines if an arbitrary filesystem entity exists relative to a specific ancestor path hierarchy.
--- @param path string? Valid relative or absolute system path location.
--- @param dir string? Target parent directory path location.
--- @param callback fun(is_path_inside_dir: boolean) Executed asynchronously with the evaluation result.
function M.is_path_inside_dir(path, dir, callback)
    local path_abs = get_clean_absolute_path(path)
    local dir_abs = get_clean_absolute_path(dir)

    if not path_abs or not dir_abs then
        callback(false)
        return
    end

    -- Force a trailing slash onto the target parent directory.
    -- This blocks prefix collision false-positives (e.g. matching '/project-backup' when checking '/project').
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

--- Inspects and extracts the canonical tracked baseline directory for the chezmoi state store.
--- Result is cached after the first successful resolution.
--- @param callback fun(src_dir: string?) Callback executed with the absolute source directory path, or nil.
function M.get_src_dir(callback)
    if cached_src_dir then
        callback(cached_src_dir)
        return
    end

    local env = os.getenv("CHEZMOI_SOURCE_DIR")

    if env and env ~= "" then
        cached_src_dir = get_clean_absolute_path(env)
        callback(cached_src_dir)
        return
    end

    cmd_source_path:async({}, function(result)
        if result.success and result.data and #result.data > 0 then
            cached_src_dir = get_clean_absolute_path(result.data[1])
        end
        callback(cached_src_dir)
    end)
end

--- Maps target file paths to their tracked chezmoi source counterparts.
--- @param file string? Target filesystem path. Nil or empty resolves the source directory itself.
--- @param callback fun(src_files: string[]?) Callback executed with resolved absolute source paths, or nil.
function M.get_src_file(file, callback)
    local args = {}
    if file and file ~= "" then
        table.insert(args, file)
    end

    cmd_source_path:async(args, function(result)
        if not result.success or not result.data or #result.data == 0 then
            callback(nil)
            return
        end

        local abs_paths = {}
        for _, src in ipairs(result.data) do
            local abs = get_clean_absolute_path(src)
            if abs then
                table.insert(abs_paths, abs)
            end
        end

        callback(#abs_paths > 0 and abs_paths or nil)
    end)
end

--- Maps chezmoi source file paths to their managed target destinations.
--- @param file string? Source repository path. Nil or empty resolves against the source directory root.
--- @param callback fun(tgt_files: string[]?) Callback executed with resolved absolute target paths, or nil.
function M.get_tgt_file(file, callback)
    local args = {}
    if file and file ~= "" then
        table.insert(args, file)
    end

    cmd_target_path:async(args, function(result)
        if not result.success or not result.data or #result.data == 0 then
            callback(nil)
            return
        end

        local abs_paths = {}
        for _, tgt in ipairs(result.data) do
            local abs = get_clean_absolute_path(tgt)
            if abs then
                table.insert(abs_paths, abs)
            end
        end

        callback(#abs_paths > 0 and abs_paths or nil)
    end)
end

--- Validates if a file resides inside the configured source directory hierarchy.
--- @param file string? Absolute or relative path to check.
--- @param callback fun(is_src: boolean) Callback executed with the final verification boolean.
function M.is_src_file(file, callback)
    M.get_src_dir(function(src_dir)
        if not src_dir then
            callback(false)
            return
        end
        M.is_path_inside_dir(file, src_dir, callback)
    end)
end

--- Validates file exclusions against the module-level ignore_patterns list.
--- @param file string? Tracked source document path.
--- @param callback fun(should_ignore: boolean) Callback executed with the exclusion verdict.
function M.should_ignore_src_file(file, callback)
    if not file or file == "" or #ignore_patterns == 0 then
        callback(false)
        return
    end

    M.get_src_dir(function(src_dir)
        if not src_dir then
            callback(false)
            return
        end

        M.is_path_inside_dir(file, src_dir, function(is_inside)
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
            for _, pattern in ipairs(ignore_patterns) do
                if normal_rel_path:match(pattern) then
                    callback(true)
                    return
                end
            end

            callback(false)
        end)
    end)
end

--- @param src string Source file path.
--- @return boolean True if the base filename starts with 'symlink_'.
function M.has_symlink_attr(src) return vim.fs.basename(src):match("^symlink_") ~= nil end

--- Prompts to open chezmoi source file instead of target.
--- @param callback fun(choice: integer) 1 = No, 2 = Yes, 3 = Don't ask again, 0 = dismissed
function M.ask_open_src_file(callback)
    vim.schedule(
        function()
            callback(
                vim.fn.confirm(
                    "Open the chezmoi source file instead?\n",
                    "&No" .. "\n&Yes" .. "\n&Don't ask again",
                    1,
                    "Question"
                )
            )
        end
    )
end

--- Prompts to apply chezmoi source file to target.
--- @param callback fun(choice: integer) 1 = No, 2 = Yes, 3 = Don't ask again, 4 = Watch, 0 = dismissed
function M.ask_apply_src_file(callback)
    vim.schedule(
        function()
            callback(
                vim.fn.confirm(
                    "Apply to the chezmoi target now?\n",
                    "&No" .. "\n&Yes" .. "\n&Don't ask again" .. "\n&Watch this file",
                    1,
                    "Question"
                )
            )
        end
    )
end

return M
