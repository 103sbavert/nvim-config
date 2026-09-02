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

return M
