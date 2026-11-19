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

local SGR_RESET = "\27[0m"
local SGR_RED = "\27[31m"
local SGR_BLUE = "\27[34m"
local SGR_GREY = "\27[90m"

--- Header and footer of an X run; the prompt takes the command, the exit line
--- takes the exit status.
local EXEC_PROMPT_FMT = table.concat({
    SGR_RED,
    "$",
    SGR_RESET,
    " ",
    SGR_BLUE,
    "%s",
    SGR_RESET,
    "\n\n",
})
local EXEC_EXIT_FMT = "\n" .. SGR_GREY .. "[exit %d]" .. SGR_RESET .. "\n"

--- Output is rendered by a libvterm instance opened on the buffer, so ANSI and
--- truecolor sequences from the child are interpreted instead of stored raw.
--- @param cmd_str string command run in the terminal to format using $ <cmd>
--- @return integer `buffer number` of the opened buffer
--- @return integer? `channel id` of the opened channel, nil if channel could not be opened
local function setup_exec_window(cmd_str)
    local buf = vim.api.nvim_create_buf(true, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "ExecOut"

    vim.api.nvim_buf_set_name(buf, ("%s: $ %s"):format(vim.o.shell, cmd_str))

    -- The terminal inherits the window size, so it must be displayed first.
    local win_id = vim.api.nvim_open_win(buf, true, { split = "below" })
    local chan = vim.api.nvim_open_term(buf, {})
    if chan == 0 then
        return buf, nil
    end

    vim.api.nvim_chan_send(chan, EXEC_PROMPT_FMT:format(cmd_str))

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

    return buf, chan
end

vim.api.nvim_create_user_command("X", function(opts)
    local args = {}
    for _, argw in ipairs(opts.fargs) do
        table.insert(args, vim.fn.expandcmd(argw))
    end
    local arg_str = table.concat(args, " ")

    local buf, chan = setup_exec_window(arg_str)
    if not chan then
        vim.notify("X: could not open terminal buffer", vim.log.levels.ERROR)
        return
    end

    local feed = vim.schedule_wrap(function(data)
        if not data then
            return
        end

        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end

        pcall(vim.api.nvim_chan_send, chan, data)
    end)

    vim.system({ vim.o.shell, vim.o.shellcmdflag, arg_str }, {
        text = true,
        stdout = function(_, data) feed(data) end,
        stderr = function(_, data) feed(data) end,
    }, function(obj) feed(EXEC_EXIT_FMT:format(obj.code)) end)
end, {
    nargs = "+",
    complete = "shellcmd",
    desc = "Runs vim.o.shell in an async environment",
})
