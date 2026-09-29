local M = {}

M.default_ignored_dirs = {
    ["vendor"] = true,
    [".git"] = true,
    ["node_modules"] = true,
}

--- @type table<boolean, table<string,string>>
M.git_diff_glyphs = {
    [true] = {
        -- Change type
        added = "",
        deleted = "",
        modified = "",
        renamed = "",
        -- Status type
        untracked = "？",
        conflict = "！",
        unstaged = "～",
        staged = "＋",
    },
    [false] = {
        -- Change type
        added = "𝗔",
        deleted = "𝗗",
        modified = "𝗠",
        renamed = "𝗥",
        -- Status type
        untracked = "？",
        conflict = "！",
        unstaged = "～",
        staged = "＋",
    },
}

--- @module "dapui.config"
--- @type table<boolean, dapui.Config.controls.icons>
M.debug_button_glyphs = {
    [true] = {
        pause = "",
        play = "",
        step_into = "",
        step_over = "",
        step_out = "",
        step_back = "",
        run_last = "",
        terminate = "",
        disconnect = "",
    },
    [false] = {

        pause = "⏸",
        play = "▶",
        step_into = "⏎",
        step_over = "⏭",
        step_out = "⏮",
        step_back = "b",
        run_last = "▶▶",
        terminate = "⏹",
        disconnect = "⏏",
    },
}

--- @type table<boolean, table<vim.diagnostic.Severity, string>>
M.lsp_diagnostic_glyphs = {
    [true] = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN] = "",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.HINT] = "󰌵",
    },
    [false] = {
        [vim.diagnostic.severity.ERROR] = "✖",
        [vim.diagnostic.severity.WARN] = "!",
        [vim.diagnostic.severity.INFO] = "ℹ",
        [vim.diagnostic.severity.HINT] = "⚑",
    },
}

--- Resolves the absolute file system path of the current target buffer.
--- @param args table? Optional autocmd event payload parameters containing buffer context.
--- @return string? Absolute file path string if valid, otherwise nil.
function M.get_current_file(args)
    if not args or not args.buf or args.buf == 0 then
        return vim.fn.expand("%:p")
    end

    local bufnr = args.buf
    local bufname = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":p")

    if not bufname or bufname == "" then
        return nil
    end

    return bufname
end

--- Checks whether any path segment is hidden (dotfile/dotdir), ignoring
--- the special "." and ".." segments.
--- @param path string File system path to check.
--- @return boolean True if any segment starts with ".".
function M.has_hidden_component(path)
    for segment in path:gmatch("[^/]+") do
        if segment:match("^%.") and segment ~= "." and segment ~= ".." then
            return true
        end
    end
    return false
end

--- Returns a function that calls require when invoked
--- @generic T
--- @param modname `T`
--- @return fun(): T
function M.lazy_require(modname)
    return function() return require(modname) end
end

--- @diagnostic disable-next-line: deprecated
local unpack = table.unpack or unpack

--- Runs a libuv async fs_* call and yields the current coroutine until it
--- completes. The resume is always deferred via vim.schedule, so code
--- after `await()` runs in a main-loop-safe (API-callable) context.
--- Must be called from within a coroutine started by `M.async_run()`.
--- @param fn function libuv function accepting a trailing callback
--- @param ... any arguments to pass to `fn` before its callback
--- @return any ... whatever the callback received (typically err, result)
function M.await(fn, ...)
    local co = coroutine.running()
    assert(co, "await() must be called from within async_run()")

    local nargs = select("#", ...)
    local args = { ... }
    args[nargs + 1] = function(...)
        local cb_nargs = select("#", ...)
        local cb_args = { ... }
        vim.schedule(function()
            local ok, err = coroutine.resume(co, unpack(cb_args, 1, cb_nargs))
            if not ok then
                vim.notify(
                    "Internal error: " .. tostring(err),
                    vim.log.levels.ERROR,
                    { title = "Async" }
                )
            end
        end)
    end

    fn(unpack(args, 1, nargs + 1))
    return coroutine.yield()
end

--- Runs `fn` as a coroutine so it may call `M.await()`.
--- @param fn function
--- @param opts? { error_title?: string } Configuration.
---   - error_title: Title for error notifications (default: "Async").
function M.async_run(fn, opts)
    local error_title = opts and opts.error_title or "Async"
    local co = coroutine.create(fn)
    local ok, err = coroutine.resume(co)
    if not ok then
        error(error_title .. " error:\n" .. tostring(err))
    end
end

--- @class ProgressHandle
--- @field step fun(self: ProgressHandle, msg: string) Updates the displayed message.
--- @field finish fun(self: ProgressHandle) Ends the progress report; idempotent.

--- Creates a progress reporter. Wraps the UI backend so callers never touch it
--- directly, and so updates are safe to trigger from fast-event contexts.
--- @param msg string Initial message.
--- @param opts? { title?: string, client?: string }
--- @return ProgressHandle
function M.progress(msg, opts)
    local handle = require("fidget.progress").handle.create({
        title = opts and opts.title or "Progress",
        message = msg,
        lsp_client = { name = opts and opts.client or "nvim" },
        cancellable = false,
    })

    local finished = false

    return {
        step = function(_, m)
            vim.schedule(function()
                if not finished then
                    handle.message = m
                end
            end)
        end,
        finish = function()
            if finished then
                return
            end
            finished = true
            vim.schedule(function() handle:finish() end)
        end,
    }
end

--- Executes a system command with standardized error handling and safe callback invocation.
--- Always invokes callback (even on error); errors also trigger vim.notify.
--- @param cmd string[] Command and arguments to execute.
--- @param callback fun(result: vim.SystemCompleted) Invoked in scheduled context after command completes.
--- @param opts? { error_title?: string, notify_on_error?: boolean } Configuration.
---   - error_title: Title for error notifications (default: command name).
---   - notify_on_error: Whether to notify on exit code ~= 0 (default: true).
function M.git_run(cmd, callback, opts)
    opts = opts or {}
    local error_title = opts.error_title or (cmd[1] or "cmd")
    local notify_on_error = opts.notify_on_error ~= false

    vim.system(cmd, {}, function(result)
        vim.schedule(function()
            if result.code ~= 0 and notify_on_error then
                local msg = vim.trim((result.stderr or result.stdout or ""))
                vim.notify(
                    msg ~= "" and msg or "Command failed: " .. error_title,
                    vim.log.levels.ERROR,
                    { title = error_title }
                )
            end
            callback(result)
        end)
    end)
end

--- Checks if a file is tracked in git. Always invokes callback.
--- Automatically notifies on git errors.
--- @param file_path string Absolute file path to check.
--- @param callback fun(is_tracked: boolean, status_line: string) Invoked in scheduled context.
---   - is_tracked: true if file is tracked (has git history), false if new/untracked.
---   - status_line: Raw git status output (e.g., "M ", "??", "A ").
function M.is_file_tracked(file_path, callback)
    M.git_run(
        { "git", "--no-pager", "status", "--porcelain", "--", file_path },
        function(result)
            local status_line = vim.trim(result.stdout or "")
            -- File is new/untracked if status starts with ?? or A
            local is_new = vim.startswith(status_line, "??")
                or vim.startswith(status_line, "A")
            callback(not is_new, status_line)
        end,
        { error_title = "Git Status", notify_on_error = true }
    )
end

--- Create a keymap group that returns a function for setting keymaps
--- @param prefix_keys string Group prefix key sequence (such as "<leader>g" for all key maps starting in "<leader>g")
--- @param default_modes string|string[] Default vim modes
--- @return fun(keys: string, func: string|function, desc: string, opts: table?, modes?: string|string[]): nil
function _G.create_keymap_group(prefix_keys, default_modes)
    return function(keys, func, desc, keymap_opts, modes)
        local final_opts = vim.tbl_deep_extend("force", {}, keymap_opts or {})
        final_opts.desc = desc
        local target_modes = modes or default_modes
        local full_keys = prefix_keys .. keys
        vim.keymap.set(target_modes, full_keys, func, final_opts)
    end
end

--- Create a toggle keymap that shows a notification
--- @param keys string Key suffix
--- @param func fun(): (string|nil, boolean|nil) Function returning message and notify flag
--- @param desc string Keymap description
--- @param opts? { buffer?: integer } Optional mapping options (buffer for a buffer-local toggle)
function _G.map_toggle_key(keys, func, desc, opts)
    local function toggle_fn()
        local message, should_notify = func()
        if should_notify and message and message ~= "" then
            vim.notify(message, vim.log.levels.INFO)
        end
    end

    local map_opts = nil
    if opts and opts.buffer then
        map_opts = { buffer = opts.buffer }
    end

    local toggle_key_group = create_keymap_group("<leader>t", { "n" })
    toggle_key_group(keys, toggle_fn, desc, map_opts)
end

--- Recursively scans a directory for a specific file name, skipping ignored directories.
--- @param root_dir string The starting directory path.
--- @param target_name string The exact name of the file to find (e.g., "main.go").
--- @param max_depth number Maximum recursion depth.
--- @param ignored_dirs table? (Optional) Set of directory names to skip as keys (e.g., { build = true }).
--- @return table List of absolute file paths matching the target name.
function M.find_files_by_name(root_dir, target_name, max_depth, ignored_dirs)
    ignored_dirs = ignored_dirs or M.default_ignored_dirs
    local results = {}

    local function scan(dir, depth)
        if depth == 0 then
            return
        end

        for name, type in vim.fs.dir(dir) do
            if type == "directory" then
                if not ignored_dirs[name] then
                    scan(vim.fs.joinpath(dir, name), depth - 1)
                end
            elseif type == "file" and name == target_name then
                table.insert(results, vim.fs.joinpath(dir, name))
            end
        end
    end

    scan(root_dir, max_depth)
    return results
end

--- Parses specified keys from an environment file.
--- @param root_dir string The base directory path.
--- @param filename string The env file name.
--- @param keys string[] List of target keys to look up.
--- @return table<string, string>|nil Map of key-value pairs, or nil if no keys were found.
function M.parse_env(root_dir, filename, keys)
    local target_file = vim.fs.joinpath(root_dir, filename)

    local file = io.open(target_file, "r")
    if not file then
        return nil
    end

    -- Single I/O read call into C stdio buffer
    local content = file:read("*a")
    file:close()

    if not content or content == "" then
        return nil
    end

    local target_set = {}
    for _, key in ipairs(keys) do
        target_set[key] = true
    end

    local results = {}

    -- Iterate through memory buffer
    for line in content:gmatch("[^\r\n]+") do
        local clean_line = line:gsub("^%s*export%s+", "")
        local trimmed = clean_line:match("^%s*(.-)%s*$")

        if trimmed ~= "" and not trimmed:match("^#") then
            local raw_key, raw_val =
                clean_line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
            if raw_key and target_set[raw_key] then
                results[raw_key] = M.shell_dequote(raw_val)
            end
        end
    end

    return next(results) and results or nil
end

--- Parses a delimited environment key across multiple directories in priority order and returns unique entries.
--- @param dirs (string|nil)[] List of directory paths to search in order.
--- @param filename string The file name to parse
--- @param key string The environment key to extract
--- @param sep? string Optional delimiter (defaults to ":").
--- @return string[]|nil List of unique parsed paths, or nil if none found.
function M.get_env_paths(dirs, filename, key, sep)
    sep = sep or ":"
    local results = {}
    local seen_items = {}
    local seen_dirs = {}

    for _, dir in ipairs(dirs) do
        if dir and dir ~= "" and not seen_dirs[dir] then
            seen_dirs[dir] = true

            local env_vars = M.parse_env(dir, filename, { key })
            if env_vars and env_vars[key] then
                local items = vim.split(
                    env_vars[key],
                    sep,
                    { plain = true, trimempty = true }
                )

                for _, item in ipairs(items) do
                    if not seen_items[item] then
                        seen_items[item] = true
                        table.insert(results, item)
                    end
                end
            end
        end
    end

    return #results > 0 and results or nil
end

--- Splits a prompt line shell-style: whitespace-separated tokens honoring
--- single/double quotes (quotes stripped, backslash escapes the next char)
--- @param str string? Raw input line, e.g. from a Snacks input prompt.
--- @return string[] Tokens with quoting removed.
function M.split_shell_words(str)
    local out, cur, quote = {}, {}, nil
    local i = 1
    str = str or ""
    while i <= #str do
        local c = str:sub(i, i)
        if quote then
            if c == quote then
                quote = nil
            elseif c == "\\" and i < #str then
                i = i + 1
                cur[#cur + 1] = str:sub(i, i)
            else
                cur[#cur + 1] = c
            end
        elseif c == '"' or c == "'" then
            quote = c
        elseif c == "\\" and i < #str then
            i = i + 1
            cur[#cur + 1] = str:sub(i, i)
        elseif c:match("%s") then
            if #cur > 0 then
                out[#out + 1] = table.concat(cur)
                cur = {}
            end
        else
            cur[#cur + 1] = c
        end
        i = i + 1
    end
    if #cur > 0 then
        out[#out + 1] = table.concat(cur)
    end
    return out
end

--- Removes shell-style quoting from a single value without splitting it
--- @param str string? Raw value, possibly containing quotes.
--- @return string Value with grouping quotes removed.
function M.shell_dequote(str)
    local out, quote = {}, nil
    local i = 1
    str = str or ""
    while i <= #str do
        local c = str:sub(i, i)
        if quote then
            if c == quote then
                quote = nil
            elseif c == "\\" and i < #str then
                i = i + 1
                out[#out + 1] = str:sub(i, i)
            else
                out[#out + 1] = c
            end
        elseif c == '"' or c == "'" then
            quote = c
        elseif c == "\\" and i < #str then
            i = i + 1
            out[#out + 1] = str:sub(i, i)
        else
            out[#out + 1] = c
        end
        i = i + 1
    end
    return table.concat(out)
end

--- Parses `KEY=value` tokens from a prompt line into an env map.
--- @param str string? Raw input line, e.g. from a Snacks input prompt.
--- @return table<string, string> Map of variable names to values.
function M.parse_env_assignments(str)
    local env = {}
    for _, item in ipairs(M.split_shell_words(str)) do
        local key, val = item:match("^([^=]+)=(.*)$")
        if key then
            env[vim.trim(key)] = val
        end
    end
    return env
end

--- Returns an unused TCP port on localhost
--- @return integer port A currently free port number.
function M.free_tcp_port()
    local tcp = assert(vim.uv.new_tcp(), "Must be able to create tcp handle")
    tcp:bind("127.0.0.1", 0)
    local port = tcp:getsockname().port
    tcp:shutdown()
    tcp:close()
    return port
end

return M
