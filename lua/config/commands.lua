-- [[ User commands ]]
-- Custom commands that do not utilize any external libraries or plugins

-- Copy the current buffer's absolute path to the system clipboard through the
-- configured clipboard provider.
--
-- See `:help provider`
vim.api.nvim_create_user_command("Copyfile", function()
    local name = vim.api.nvim_buf_get_name(0)
    if name == "" then
        vim.notify("Copyfile: buffer has no file name", vim.log.levels.WARN)
        return
    end

    local path = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))

    vim.fn.setreg("+", path)

    vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Copy current buffer path" })

--- Files to source before each :Exec command. Entries may be absolute or
--- relative and may contain `~` and environment variables
--- @type string[]
local exec_source_files = {}

local exec_ns = vim.api.nvim_create_namespace("exec_output")
local exec_buf
local exec_job
local exec_gen = 0

vim.api.nvim_create_user_command("X", function(opts)
    local lines = {}
    for _, raw in ipairs(exec_source_files) do
        local p = vim.fn.shellescape(vim.fn.expand(raw))
        table.insert(lines, ("[ -r %s ] && source %s"):format(p, p))
    end
    table.insert(lines, opts.args)
    local script = table.concat(lines, "\n")

    -- Stop any in-flight run and bump the generation so its pending
    -- callbacks bail instead of writing into the reused buffer.
    if exec_job then
        exec_job:kill("sigterm")
        exec_job = nil
    end
    exec_gen = exec_gen + 1
    local gen = exec_gen

    -- Reuse the buffer if it is still valid
    if not (exec_buf and vim.api.nvim_buf_is_valid(exec_buf)) then
        exec_buf = vim.api.nvim_create_buf(true, true)
        vim.bo[exec_buf].buftype = "nofile"
        vim.bo[exec_buf].filetype = "ExecOut"
    end
    local buf = exec_buf

    local function write(first, last, repl)
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, first, last, false, repl)
        vim.bo[buf].modifiable = false
    end

    vim.api.nvim_buf_set_name(buf, ("ExecOut://%d %s"):format(buf, opts.args))
    vim.api.nvim_buf_clear_namespace(buf, exec_ns, 0, -1)
    write(0, -1, { "$ " .. opts.args, "" })

    vim.api.nvim_buf_set_extmark(buf, exec_ns, 0, 0, {
        end_col = 1,
        hl_group = "ExecPrompt",
    })

    vim.api.nvim_buf_set_extmark(buf, exec_ns, 0, 2, {
        end_col = 2 + #opts.args,
        hl_group = "ExecCommand",
    })

    vim.api.nvim_set_current_buf(buf)

    local function feed(data, hl)
        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end

        local last = vim.api.nvim_buf_line_count(buf)
        local tail = vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1]
            or ""
        local parts = vim.split(data, "\n", { plain = true })
        parts[1] = tail .. parts[1]
        write(last - 1, last, parts)

        if hl then
            local new_last = vim.api.nvim_buf_line_count(buf)
            for l = last - 1, new_last - 1 do
                vim.api.nvim_buf_set_extmark(buf, exec_ns, l, 0, {
                    line_hl_group = hl,
                })
            end
        end

        -- Follow output
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == buf then
                local cur = vim.api.nvim_win_get_cursor(win)
                if cur[1] >= last - 1 then
                    vim.api.nvim_win_set_cursor(
                        win,
                        { vim.api.nvim_buf_line_count(buf), 0 }
                    )
                end
            end
        end
    end

    -- Run `fn` on the main loop, but only if this invocation is still current.
    local function schedule_current(fn)
        vim.schedule(function()
            if gen == exec_gen then
                fn()
            end
        end)
    end

    local function on_data(hl)
        return function(_, data)
            if data then
                schedule_current(function() feed(data, hl) end)
            end
        end
    end

    exec_job = vim.system({ "zsh", "-c", script }, {
        text = true,
        stdout = on_data(nil),
        stderr = on_data("DiagnosticError"),
    }, function(obj)
        schedule_current(function()
            feed(("\n[exit %d]\n"):format(obj.code), "ExecExit")
            exec_job = nil
        end)
    end)
end, {
    nargs = "+",
    complete = "shellcmd",
    desc = "Async zsh -c with $ZSH_CUSTOM sources into a scratch buffer",
})
