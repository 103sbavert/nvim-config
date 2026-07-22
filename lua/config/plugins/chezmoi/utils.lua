local M = {}

local UT = require("config.utils")
local get_cmd_src_path = UT.lazy_require("nvim-chezmoi.chezmoi.commands.source_path")
local get_cmd_edit = UT.lazy_require("nvim-chezmoi.chezmoi.commands.edit")
local get_czm_cache = UT.lazy_require("nvim-chezmoi.chezmoi.cache")

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
function M.get_clean_absolute_path(p)
    if not p or p == "" then
        return nil
    end

    return vim.fs.abspath(p)
end

--- Returns the cached source directory (nil if not yet resolved).
--- @return string?
function M.get_cached_src_dir()
    return cached_src_dir
end

--- Inspects and extracts the canonical tracked baseline directory for the chezmoi state store.
--- Result is cached after the first successful resolution.
--- @param callback fun(src_dir: string?) Callback executed with the absolute source directory path, or nil.
function M.get_src_dir_async(callback)
    if cached_src_dir then
        callback(cached_src_dir)
        return
    end

    local env = os.getenv("CHEZMOI_SOURCE_DIR")

    if env and env ~= "" then
        cached_src_dir = M.get_clean_absolute_path(env)
        callback(cached_src_dir)
        return
    end

    get_cmd_src_path():async({}, function(result)
        if result.success and result.data and #result.data > 0 then
            cached_src_dir = M.get_clean_absolute_path(result.data[1])
        end
        callback(cached_src_dir)
    end)
end

--- @param src string Source file path.
--- @return boolean True if the base filename starts with 'symlink_'.
function M.has_symlink_attr(src) return vim.fs.basename(src):match("^symlink_") ~= nil end

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

--- Opens chezmoi source file for editing via chezmoi edit command.
--- @param file string?
function M.edit_chezmoi(file)
    file = file or vim.api.nvim_buf_get_name(0)
    local res = get_cmd_edit():exec(file)

    if not res or res.success then
        vim.notify("Opened source file", vim.log.levels.INFO, { title = "Chezmoi" })
    else
        local m = table.concat(res.data)
        vim.notify(m, vim.log.levels.ERROR, { title = "Chezmoi" })
    end
end

return M
