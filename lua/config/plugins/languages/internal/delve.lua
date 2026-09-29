local M = {}

local LISTEN_HOST = "127.0.0.1"

--- @param msg string
local function notify_err(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "Go DAP" })
end

--- Common DAP attach config
local attach_base = { type = "go", request = "attach", mode = "remote" }

--- Finds the `main.go` package to debug, prompting only when ambiguous.
local function detect_main()
    local cwd = vim.fn.getcwd(0, 0)
    local main_files =
        require("config.utils").find_files_by_name(cwd, "main.go", 6)

    if #main_files == 1 then
        return vim.fs.dirname(main_files[1])
    end

    -- NOTE: DAP has custom logic for handling so we can't use
    -- the global wrappers for coroutine here
    return coroutine.create(function(dap_co)
        if #main_files == 0 then
            vim.ui.input({
                prompt = "No main.go found. Specify path: ",
                default = cwd .. "/",
                completion = "file",
            }, function(input)
                if input and input ~= "" then
                    local stat = vim.uv.fs_stat(input)
                    if stat and stat.type == "directory" then
                        coroutine.resume(dap_co, input)
                    else
                        coroutine.resume(dap_co, vim.fs.dirname(input))
                    end
                else
                    coroutine.resume(dap_co, nil)
                end
            end)
        else
            vim.ui.select(main_files, {
                prompt = "Select main.go:",
                format_item = function(item)
                    return vim.fs.normalize(item):sub(#cwd + 2)
                end,
            }, function(choice)
                if choice then
                    coroutine.resume(dap_co, vim.fs.dirname(choice))
                else
                    coroutine.resume(dap_co, nil)
                end
            end)
        end
    end)
end

--- Prompt for program argv via Snacks. DAP coroutine: resolves to a list.
--- Same pattern as `detect_main`: DAP resumes its own coroutine with
--- whatever this one yields back through `dap_co`.
--- @return thread
local function prompt_args()
    return coroutine.create(function(dap_co)
        Snacks.input(
            { prompt = "Args: " },
            function(value)
                coroutine.resume(
                    dap_co,
                    require("config.utils").split_shell_words(value or "")
                )
            end
        )
    end)
end

--- Prompt for `KEY=value ...` env assignments via Snacks. Resolves to a map.
--- @return thread
local function prompt_env()
    return coroutine.create(function(dap_co)
        Snacks.input(
            { prompt = "Env (KEY=value ...): " },
            function(value)
                coroutine.resume(
                    dap_co,
                    require("config.utils").parse_env_assignments(value)
                )
            end
        )
    end)
end

--- DAP configurations for delve
local configs = {
    vim.tbl_extend("force", attach_base, {
        name = "Debug Main",
        program = detect_main,
    }),
    vim.tbl_extend("force", attach_base, {
        name = "Debug (Current)",
        program = "${file}",
    }),
    vim.tbl_extend("force", attach_base, {
        name = "Debug Main (Args & Env)",
        program = detect_main,
        args = prompt_args,
        env = prompt_env,
    }),
}

--- Build `program` into a temp binary with debug flags.
--- @param program string
--- @param cb fun(bin: string?, err: string?)
local function build_debug_bin(program, cb)
    local target = program
    local stat = vim.uv.fs_stat(target)

    if not (stat and stat.type == "directory") then
        target = vim.fs.dirname(target)
    end

    local bin = vim.fn.tempname()
    local cmd = { "go", "build", "-gcflags=all=-N -l", "-o", bin, target }

    -- NOTE: `go` build fails when the caller cwd sits inside another module
    -- ("directory ... outside main module").
    vim.system(cmd, { cwd = target, text = true }, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                pcall(os.remove, bin)
                local err = vim.trim(res.stderr or "")
                if err == "" then
                    err = "go build failed for " .. target
                end
                cb(nil, err)
                return
            end
            cb(bin, nil)
        end)
    end)
end

--- Create the terminal buffer that nvim-dap-view shows as its Console.
--- Never executes the stock string fallback (`belowright new`): that would
--- open a second window showing the same buffer next to the Console.
--- @param config dap.Configuration
--- @return integer? buf
local function tty_term_buf(config)
    local dap = require("dap")
    local win_cmd = dap.defaults.go.terminal_win_cmd
    if type(win_cmd) == "function" then
        return win_cmd(config)
    end
    return vim.api.nvim_create_buf(false, false)
end

--- Abort a launch: drop a half-built binary (if any) and report.
--- @param bin string?
--- @param msg string
local function abort(bin, msg)
    if bin then
        pcall(os.remove, bin)
    end
    notify_err(msg)
end

--- @param name string tool name expected on PATH
--- @return boolean ok
local function assert_tool(name)
    if vim.fn.executable(name) ~= 1 then
        notify_err(name .. " not found in PATH")
        return false
    end
    return true
end

--- Spawn headless delve in the dap-view Console buffer.
--- @param term_buf integer
--- @param bin string
--- @param port integer
--- @param args string[]
--- @param env table<string, string>?
--- @return integer? jobid
local function spawn_headless(term_buf, bin, port, args, env)
    local dlv_cmd = {
        "dlv",
        "--headless",
        "--listen=" .. LISTEN_HOST .. ":" .. port,
        "exec",
        bin,
    }
    if #args > 0 then
        vim.list_extend(dlv_cmd, { "--" })
        vim.list_extend(dlv_cmd, args)
    end
    local jobid
    vim.api.nvim_buf_call(
        term_buf,
        function()
            jobid = vim.fn.jobstart(dlv_cmd, {
                term = true,
                env = (type(env) == "table" and next(env) ~= nil) and env
                    or nil,
            })
        end
    )
    if not jobid or jobid <= 0 then
        return nil
    end
    return jobid
end

--- Second half of the adapter: runs scheduled after the async build.
--- @param callback fun(adapter: dap.Adapter)
--- @param config dap.Configuration
--- @param bin string?
--- @param err string?
local function on_build_finish(callback, config, bin, err)
    if bin == nil then
        notify_err(err or "go build failed")
        return
    end
    local port = require("config.utils").free_tcp_port()
    local term_buf = tty_term_buf(config)
    if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
        abort(bin, "could not create terminal buffer")
        return
    end
    local jobid =
        spawn_headless(term_buf, bin, port, config.args or {}, config.env)
    if not jobid then
        abort(bin, "failed to start headless delve")
        return
    end
    config.__tty_buf = term_buf
    config.__tty_bin = bin
    callback({ type = "server", host = LISTEN_HOST, port = port })
end

--- Register the delve adapter, add DAP attach configurations
function M.setup()
    local dap = require("dap")

    dap.adapters.go = function(callback, config)
        if not (assert_tool("dlv") and assert_tool("go")) then
            return
        end

        local program = config.program
        if type(program) ~= "string" or program == "" then
            notify_err("could not resolve program to build")
            return
        end
        if type(config.args) == "string" then
            config.args = require("config.utils").split_shell_words(config.args)
        end

        build_debug_bin(
            program,
            function(bin, err) on_build_finish(callback, config, bin, err) end
        )
    end

    dap.configurations.go = configs

    dap.listeners.on_session["delve_tty"] = function(_, session)
        local cfg = session and session.config
        if cfg == nil or cfg.type ~= "go" then
            return
        end
        if cfg.__tty_buf and vim.api.nvim_buf_is_valid(cfg.__tty_buf) then
            session.term_buf = cfg.__tty_buf
        end
    end

    local function cleanup(session)
        local cfg = (session and session.config) or {}
        if cfg.type ~= "go" then
            return
        end

        if cfg.__tty_bin then
            pcall(os.remove, cfg.__tty_bin)
            cfg.__tty_bin = nil
        end
        cfg.__tty_job = nil
    end
    dap.listeners.before.event_terminated["delve_tty"] = cleanup
    dap.listeners.before.event_exited["delve_tty"] = cleanup
end

return M
