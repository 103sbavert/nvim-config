local M = {}

local UT = require("config.utils")

--- @type fun(): ChezmoiSourcePath
local get_cmd_src_path =
    UT.lazy_require("nvim-chezmoi.chezmoi.commands.source_path")

--- @type fun(): ChezmoiCache
local get_czm_cache = UT.lazy_require("nvim-chezmoi.chezmoi.cache")

local uv = vim.uv or vim.loop

local cached_src_dir = nil

--- Lua patterns matched against relative source paths. Matching files are skipped.
--- @type string[]
M.ignore_patterns = {
    "run_",
    "%.chezmoi",
    "%.gitignore",
    "%.git/",
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

--- Returns the cached source directory (nil if not yet resolved).
--- @return string?
function M.get_cached_src_dir() return cached_src_dir end

--- Awaitable: resolves and caches the canonical tracked baseline directory for
--- the chezmoi state store. Must run inside a coroutine started by `UT.async_run()`.
--- @return string?
local function get_src_dir()
    if cached_src_dir then
        return cached_src_dir
    end

    local env = os.getenv("CHEZMOI_SOURCE_DIR")

    if env and env ~= "" then
        cached_src_dir = get_clean_absolute_path(env)
        return cached_src_dir
    end

    local result = UT.await(function(cb) get_cmd_src_path():async({}, cb) end)

    if result.success and result.data and #result.data > 0 then
        cached_src_dir = get_clean_absolute_path(result.data[1])
    end

    return cached_src_dir
end

--- Inspects and extracts the canonical tracked baseline directory for the chezmoi state store.
--- Result is cached after the first successful resolution.
--- @param callback fun(src_dir: string?) Callback executed with the absolute source directory path, or nil.
function M.get_src_dir_async(callback)
    UT.async_run(
        function() callback(get_src_dir()) end,
        { error_title = "Chezmoi" }
    )
end

--- Awaitable: checks if path is inside dir. Must run inside a coroutine
--- started by `UT.async_run()`.
--- @param path string?
--- @param dir string?
--- @return boolean
local function is_path_inside_dir(path, dir)
    local path_abs = get_clean_absolute_path(path)
    local dir_abs = get_clean_absolute_path(dir)

    if not path_abs or not dir_abs then
        return false
    end

    if not vim.endswith(dir_abs, "/") then
        dir_abs = dir_abs .. "/"
    end

    local err, stat = UT.await(uv.fs_stat, path_abs)
    if err or not stat then
        return false
    end

    return path_abs:find(dir_abs, 1, true) == 1
end

--- Awaitable: resolves the source directory, preferring an already known
--- value. Must run inside a coroutine started by `UT.async_run()`.
--- @param src_dir string? Pre-resolved source directory, if any.
--- @return string?
local function resolve_src_dir(src_dir)
    if src_dir and src_dir ~= "" then
        return src_dir
    end

    return get_src_dir()
end

--- Awaitable: checks if file is a chezmoi source file. Must run inside a
--- coroutine started by `UT.async_run()`.
--- @param file string?
--- @param src_dir string? Pre-resolved source directory, skips resolution when given.
--- @return boolean
local function is_src_file(file, src_dir)
    local dir = resolve_src_dir(src_dir)
    if not dir then
        return false
    end

    return is_path_inside_dir(file, dir)
end

--- Async check if file is a chezmoi source file.
--- @param file string?
--- @param callback fun(is_src: boolean)
--- @param src_dir string? Pre-resolved source directory, skips resolution when given.
function M.is_src_file_async(file, callback, src_dir)
    UT.async_run(
        function() callback(is_src_file(file, src_dir)) end,
        { error_title = "Chezmoi" }
    )
end

--- Async resolve target file to its chezmoi source counterpart(s).
--- @param file string?
--- @param callback fun(src_files: string[]?)
function M.get_src_file_async(file, callback)
    if not file or file == "" then
        callback(nil)
        return
    end

    get_cmd_src_path():async({ file }, function(result)
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

--- Awaitable: checks if source file should be ignored. Must run inside a
--- coroutine started by `UT.async_run()`.
--- @param file string?
--- @param src_dir string? Pre-resolved source directory, skips resolution when given.
--- @return boolean
local function should_ignore_src_file(file, src_dir)
    if not file or file == "" then
        return false
    end

    local dir = resolve_src_dir(src_dir)
    if not dir then
        return false
    end

    if not is_path_inside_dir(file, dir) then
        return false
    end

    local rel_path = vim.fs.relpath(dir, file)
    if not rel_path or rel_path == "" then
        return false
    end

    local normal_rel_path = vim.fs.normalize(rel_path)
    if UT.has_hidden_component(normal_rel_path) then
        return true
    end

    for _, pattern in ipairs(M.ignore_patterns) do
        if normal_rel_path:match(pattern) then
            return true
        end
    end

    return false
end

--- @class ChezmoiClassification
--- @field is_src boolean File lives inside the chezmoi source directory.
--- @field ignored boolean Source file matched an ignore rule.

--- Classifies a file in one call, short-circuiting once the answer is known.
--- @param file string?
--- @param opts? { src_dir?: string } Pre-resolved source directory.
--- @param callback fun(result: ChezmoiClassification)
function M.classify_async(file, opts, callback)
    UT.async_run(function()
        local dir = resolve_src_dir(opts and opts.src_dir)

        if not dir or not file or file == "" then
            callback({ is_src = false, ignored = false })
            return
        end

        if not is_src_file(file, dir) then
            callback({ is_src = false, ignored = false })
            return
        end

        callback({
            is_src = true,
            ignored = should_ignore_src_file(file, dir),
        })
    end, { error_title = "Chezmoi" })
end

--- @param src string Source file path.
--- @return boolean True if the base filename starts with 'symlink_'.
function M.has_symlink_attr(src)
    return vim.fs.basename(src):match("^symlink_") ~= nil
end

--- Populates filetype cache for chezmoi source file.
--- @param ft string? Filetype string.
--- @param src_file string Source file path.
function M.populate_ft_cache(ft, src_file)
    if ft and ft ~= "" then
        get_czm_cache().new("ft_detect", { src_file }, {
            args = {},
            success = true,
            data = { ft = ft },
        })
    end
end

return M
