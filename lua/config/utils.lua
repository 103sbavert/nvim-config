local M = {}

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
    local buf_id = 0

    if args and args.buf then
        buf_id = args.buf
    end

    if not vim.api.nvim_buf_is_valid(buf_id) then
        return nil
    end

    local buf_name = vim.api.nvim_buf_get_name(buf_id)

    if not buf_name or buf_name == "" then
        return nil
    end

    return buf_name
end

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

--- Delays Neovim's exit until a job finishes. The job is fetched lazily, so this
--- can be armed before the job exists.
--- @param get_job fun(): Job? Resolver for the job to wait on.
--- @param opts? { on_wait?: fun(), timeout?: integer, interval?: integer }
--- @return fun() dispose Tears down the hook; idempotent, safe in fast-event contexts.
function M.inhibit_exit(get_job, opts)
    local timeout = opts and opts.timeout or 7000
    local interval = opts and opts.interval or 10

    local group = vim.api.nvim_create_augroup(
        "InhibitExit-" .. tostring(math.random()),
        { clear = true }
    )

    vim.api.nvim_create_autocmd({ "ExitPre" }, {
        group = group,
        once = true,
        callback = function()
            local job = get_job()
            if not job then
                return
            end

            if opts and opts.on_wait then
                opts.on_wait()
            end

            job:wait(timeout, interval, true)
        end,
    })

    local disposed = false

    return function()
        if disposed then
            return
        end
        disposed = true
        -- Deleting the group also deletes its autocmd. Scheduled because exit
        -- callbacks may land in a fast-event context.
        vim.schedule(
            function() pcall(vim.api.nvim_del_augroup_by_id, group) end
        )
    end
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
--- @param group_name string Label for the key group, shown in mini.clue popup
--- @param prefix_keys string Group prefix key sequence (such as "<leader>g" for all key maps starting in "<leader>g")
--- @param default_modes string|string[] Default vim modes
--- @return fun(keys: string, func: string|function, desc: string, opts: table?, modes?: string|string[]): nil
function _G.create_keymap_group(group_name, prefix_keys, default_modes)
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
function _G.map_toggle_key(keys, func, desc)
    local function toggle_fn()
        local message, should_notify = func()
        if should_notify and message and message ~= "" then
            vim.notify(message, vim.log.levels.INFO)
        end
    end

    local toggle_key_group = create_keymap_group("[t]oggle", "<leader>t", { "n" })
    toggle_key_group(keys, toggle_fn, desc)
end

return M
