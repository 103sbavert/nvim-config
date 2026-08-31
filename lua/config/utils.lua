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

--- Serializes a single string or an array of string arguments into a single space-separated sequence.
--- @param args string | string[] Input target arguments list or scalar value.
--- @return string Formatted plain text command-line string parameter.
function M.to_str(args)
    if type(args) == "table" then
        return table.concat(args, " ")
    end
    return args
end

--- Makes a progress notifier with Snack
--- @param msg string
--- @param id? string
--- @param opts? { title: string, timeout: boolean, history: boolean }
function M.notify_progress(msg, id, opts)
    --- @type snacks.notifier.Notif.opts
    local notifier_opts = opts or {}

    notifier_opts.id = id or tostring(math.random(1e9))
    notifier_opts.title = opts and opts.title or "Information"
    notifier_opts.history = opts and opts.history or false
    notifier_opts.timeout = opts and opts.timeout or false
    notifier_opts.opts = function(n) n.icon = Snacks.util.spinner() end

    Snacks.notifier.notify(msg, vim.log.levels.INFO, opts)
end

--- Returns a function that calls require when invoked
--- @generic T
--- @param modname `T`
--- @return fun(): T
function M.lazy_require(modname)
    return function() return require(modname) end
end

return M
