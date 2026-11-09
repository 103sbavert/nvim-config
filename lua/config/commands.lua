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

    local path = vim.fs.normalize(name)

    vim.fn.setreg("+", path)

    vim.notify("Copied: " .. path, vim.log.levels.INFO)
end, { desc = "Copy current buffer path" })

--- Files to source before each :Exec command. Entries may be absolute or
--- relative and may contain `~` and environment variables
--- @type string[]
local exec_source_files = {}

local exec_ns = vim.api.nvim_create_namespace("exec_output")

local function build_script(cmd_args)
    local lines = {}
    for _, raw in ipairs(exec_source_files) do
        local p = vim.fn.shellescape(vim.fn.expand(raw))
        table.insert(lines, ("[ -r %s ] && source %s"):format(p, p))
    end
    table.insert(lines, cmd_args)
    return table.concat(lines, "\n")
end

local function setup_exec_window(cmd_args)
    local buf = vim.api.nvim_create_buf(true, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "ExecOut"
    vim.bo[buf].bufhidden = "wipe"

    local win_id = vim.api.nvim_open_win(buf, true, { split = "below" })

    local function write(first, last, repl)
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, first, last, false, repl)
        vim.bo[buf].modifiable = false
    end

    vim.api.nvim_buf_set_name(buf, ("ExecOut://%d %s"):format(buf, cmd_args))
    vim.api.nvim_buf_clear_namespace(buf, exec_ns, 0, -1)
    write(0, -1, { "$ " .. cmd_args, "" })

    vim.api.nvim_buf_set_extmark(buf, exec_ns, 0, 0, {
        end_col = 1,
        hl_group = "ExecPrompt",
    })

    vim.api.nvim_buf_set_extmark(buf, exec_ns, 0, 2, {
        end_col = 2 + #cmd_args,
        hl_group = "ExecCommand",
    })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
        once = true,
        callback = function()
            if
                vim.api.nvim_buf_is_valid(buf)
                and vim.api.nvim_win_is_valid(win_id)
                and vim.api.nvim_win_get_buf(win_id) == buf
            then
                vim.api.nvim_win_close(win_id, true)
            end
        end,
    })

    return buf, write
end

vim.api.nvim_create_user_command("X", function(opts)
    local script = build_script(opts.args)
    local buf, write = setup_exec_window(opts.args)

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

        local cur_win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_buf(cur_win) == buf then
            local cur = vim.api.nvim_win_get_cursor(cur_win)
            if cur[1] >= last - 1 then
                vim.api.nvim_win_set_cursor(
                    cur_win,
                    { vim.api.nvim_buf_line_count(buf), 0 }
                )
            end
        end
    end

    local function on_data(hl)
        return function(_, data)
            if data then
                vim.schedule(function() feed(data, hl) end)
            end
        end
    end

    vim.system({ "zsh", "-c", script }, {
        text = true,
        stdout = on_data(nil),
        stderr = on_data("DiagnosticError"),
    }, function(obj)
        vim.schedule(
            function() feed(("\n[exit %d]\n"):format(obj.code), "ExecExit") end
        )
    end)
end, {
    nargs = "+",
    complete = "shellcmd",
    desc = "Async zsh -c with $ZSH_CUSTOM sources into a new horizontal split",
})
