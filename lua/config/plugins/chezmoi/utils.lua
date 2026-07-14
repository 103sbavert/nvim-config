local M = {}

local commands = require("chezmoi.commands")
local chezmoi_config = require("chezmoi").config

local cached_chezmoi_src_dir = os.getenv("CHEZMOI_SOURCE_DIR")

local common_utils = require("config.utils")
local symlink_pattern = "^symlink_"

--- Directs standard error diagnostic output streams to the native Neovim notification engine.
--- @param _ any Ignored positional context variable.
--- @param data string Standard error diagnostic stream raw text packet chunk payload.
local function notify_stderr(_, data)
    if type(data) == "string" and data ~= "" then
        vim.notify(data, vim.log.levels.WARN, { title = "Chezmoi" })
    end
end

--- Validates if the given source path implies an internal chezmoi symlink configuration target attribute prefix.
--- @param src string Target source file path string context.
--- @return boolean True if the absolute base file name starts with 'symlink_'.
function M.has_symlink_attr(src) return (vim.fs.basename(src):match(symlink_pattern)) ~= nil end

--- Invokes an asynchronous chezmoi state synchronization run targeted on destination mirror paths.
--- @param tgt_files string[] | string Destination path vectors inside the configured file system environment.
--- @param on_exit? fun(cmd_res: table, signal: number) Lifecycle completion hook callback.
function M.apply_tgt_files(tgt_files, on_exit)
    commands.apply({
        targets = tgt_files,
        args = { "--force", "--no-tty" },
        on_stderr = notify_stderr,
        on_exit = on_exit,
    })
end

--- Invokes an asynchronous chezmoi state synchronization run targeted explicitly from source tracking paths.
--- @param src_files string[] | string Source control repository file configurations.
--- @param on_exit? fun(cmd_res: table, signal: number) Lifecycle completion hook callback.
function M.apply_src_files(src_files, on_exit)
    commands.apply({
        args = { "--no-tty", "--force", "--source-path", common_utils.to_str(src_files) },
        on_stderr = notify_stderr,
        on_exit = on_exit,
    })
end

--- Determines if an arbitrary filesystem entity exists relative to a specific ancestor path structure hierarchy.
--- @param path string? Valid relative or absolute system path location.
--- @param dir string? Target parent repository or structural directory path location.
--- @return boolean True if the canonical resolved representation indicates root inclusion.
function M.is_path_inside_dir(path, dir)
    if not path or not dir then
        return false
    end

    local path_abs = vim.fs.abspath(path)
    local dir_abs = vim.fs.abspath(dir)

    if not path_abs or not dir_abs then
        return false
    end

    if not vim.uv.fs_stat(path) then
        return false
    end

    return path_abs:find(dir_abs, 1, true) == 1
end

--- Maps local file system definitions to underlying target paths registered in the active chezmoi state tracker.
--- @param file (string | string[])? Source file vector parameter paths or target entity list tracking points.
--- @param on_exit? fun(code: number, signal: number) Lifecycle completion hook callback.
--- @return string[]? Resolved system collection containing mapped source references.
function M.get_src_file(file, on_exit)
    file = file or {}
    local source_paths = commands.source_path({ targets = file, on_stderr = function() end, on_exit = on_exit })

    if not source_paths then
        return nil
    end

    if type(source_paths) ~= "table" then
        return nil
    end

    if vim.tbl_isempty(source_paths) then
        return nil
    end

    local abs_paths = {}

    for _, source in ipairs(source_paths) do
        if source and source ~= "" then
            local abs_source = vim.fs.abspath(source)
            if abs_source and abs_source ~= "" then
                table.insert(abs_paths, abs_source)
            end
        end
    end

    if vim.tbl_isempty(abs_paths) then
        return nil
    end

    return abs_paths
end

--- Inspects and extracts the canonical tracked baseline directory for the state store structure context.
--- @return string? Absolute tracking directory path if accessible.
function M.get_src_dir()
    if cached_chezmoi_src_dir and cached_chezmoi_src_dir ~= "" then
        return cached_chezmoi_src_dir
    end

    local env = os.getenv("CHEZMOI_SOURCE_DIR")

    if env and env ~= "" then
        cached_chezmoi_src_dir = vim.fs.abspath(env)
        return cached_chezmoi_src_dir
    end

    local source_paths = M.get_src_file()

    if source_paths then
        cached_chezmoi_src_dir = source_paths[1]
        return cached_chezmoi_src_dir
    end

    return nil
end

--- Determines if an individual target document falls contextually inside the chezmoi source framework domain.
--- @param file string? Targeted physical address path value context.
--- @return boolean True if path resides structural depths inside active source root.
function M.is_src_file(file)
    local chezmoi_src_dir = M.get_src_dir()

    if not chezmoi_src_dir or chezmoi_src_dir == "" then
        return false
    end

    return M.is_path_inside_dir(file, chezmoi_src_dir)
end

--- Validates file exclusions against explicit user configuration layout rules defined inside standard global parameters.
--- @param file string Tracked source document parameter path pointer.
--- @return boolean True if internal module parameters mandate structural omission patterns on target configuration.
function M.should_ignore_src_file(file)
    if not file or file == "" then
        return false
    end

    local src_dir = M.get_src_dir()

    if not src_dir or src_dir == "" then
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

    if not normal_rel_path or normal_rel_path == "" then
        return false
    end

    local patterns = chezmoi_config.edit and chezmoi_config.edit.ignore_patterns

    if type(patterns) ~= "table" then
        return false
    end

    for _, pattern in ipairs(patterns) do
        if type(pattern) == "string" and pattern ~= "" then
            if normal_rel_path:match(pattern) then
                return true
            end
        end
    end

    return false
end

--- Dispatches file paths straight to the editing subsystem parameters to initiate text updates.
--- @param files string | string[] Single document identifier context string or tracking group listing array.
--- @param args string[]? Supplemental control syntax string parameters payload passed to editing subprocess context.
function M.open_src_file(files, args) commands.edit({ targets = files, args = args or {} }) end

--- Prompts to open chezmoi source file instead of target.
--- @return integer 1 = No, 2 = Yes, 3 = Don't ask again, 0 = dismissed
function M.ask_open_src_file()
    return vim.fn.confirm(
        "Open the chezmoi source file instead?\n",
        "&no\n" .. "&yes\n" .. "&don't ask again",
        1,
        "Question"
    )
end

--- Prompts to apply chezmoi source file to target.
--- @return integer 1 = No, 2 = Yes, 3 = Don't ask again, 4 = Watch, 0 = dismissed
function M.ask_apply_src_file()
    return vim.fn.confirm(
        "Apply to the chezmoi target now?\n",
        "&no\n" .. "&yes\n" .. "&don't ask again\n" .. "&watch this file",
        1,
        "Question"
    )
end

return M
