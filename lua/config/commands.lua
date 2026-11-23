local copy_args = {
    ["bufpath"] = function()
        return vim.fs.normalize(vim.api.nvim_buf_get_name(0))
    end,
    ["buftext"] = function()
        return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    end,
    ["tabcd"] = function() return vim.fn.getcwd(-1, 0) end,
    ["wincd"] = function() return vim.fn.getcwd(0, 0) end,
}

-- [[ User commands ]]
-- Custom commands that do not utilize any external libraries or plugins

-- Copy the current buffer's absolute path to the system clipboard through the
-- configured clipboard provider.
--
-- See `:help provider`
vim.api.nvim_create_user_command("Copy", function(args)
    local target = args.fargs[1]
    local get_text = copy_args[target]

    assert(
        get_text ~= nil and type(get_text) == "function",
        string.format("Copy: Invalid argument type %s", target)
    )

    local res = get_text()
    if res == "" then
        local err = string.format("Copy: %s is empty or not present", target)
        vim.notify(err, vim.log.levels.WARN)
        return
    end

    assert(vim.fn.setreg("+", res) == 0, "Copy: Unable to copy to register '+'")

    local lines = select(2, res:gsub("\n", "")) + 1
    local msg
    if lines == 1 then
        local char_count = vim.fn.strchars(res)
        msg = string.format(
            "Copied: %s",
            char_count < 30 and res or tostring(char_count) .. " chars"
        )
    else
        msg = string.format("Copied: %d lines", lines)
    end
    vim.notify(msg, vim.log.levels.INFO)
end, {
    nargs = 1,
    desc = "Copy buffer content, path or cwd",
    complete = function(arglead)
        local keys = vim.tbl_keys(copy_args)
        table.sort(keys)
        return vim.tbl_filter(
            function(key) return vim.startswith(key, arglead) end,
            keys
        )
    end,
})

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
    vim.api.nvim_open_win(buf, true, { split = "below" })
    local chan = vim.api.nvim_open_term(buf, {})
    if chan == 0 then
        return buf, nil
    end

    vim.api.nvim_chan_send(chan, EXEC_PROMPT_FMT:format(cmd_str))

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
