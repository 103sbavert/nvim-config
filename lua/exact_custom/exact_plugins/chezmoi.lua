require("chezmoi").setup({
    edit = {
        watch = false,
        force = false,
        ignore_patterns = {
            "run_",
            "%.chezmoi",
            "%.gitignore",
            "%.git/",
            "%/%.[^%.%/]",
            "^%.[^%.%/]",
        },
    },
    events = {
        on_open = {
            notification = {
                enable = true,
                msg = "Opened a chezmoi-managed file",
                opts = {},
            },
        },
        on_watch = {
            notification = {
                enable = true,
                msg = "This file will be automatically applied",
                opts = {},
            },
        },
        on_apply = {
            notification = {
                enable = true,
                msg = "Successfully applied",
                opts = {},
            },
        },
    },
    telescope = {
        select = { "<CR>" },
    },
})

local commands = require("chezmoi.commands")
local chezmoi_config = require("chezmoi").config
local cached_chezmoi_src_dir = os.getenv("CHEZMOI_SOURCE_DIR")
local symlink_pattern = "^symlink_"
local CZM_STATUSLINE_HI = ("%#MiniStatuslineChezmoi# [chezmoi] %*"):gsub("%%", "%%%%")
local statusline = require("mini.statusline")

--- @param args table?
--- @return string?
local function get_current_file(args)
    local buf = 0

    if args and args.buf then
        buf = args.buf
    end

    local buf_name = vim.api.nvim_buf_get_name(buf)

    if buf_name == "" or vim.bo.buftype ~= "" then
        return nil
    end

    if buf_name:sub(1, 1) == "-" then
        buf_name = "\\" .. buf_name
    end

    return buf_name
end

--- @param args string | string[]
local function to_str(args)
    if type(args) == "table" then
        return table.concat(args, " ")
    end
    return args
end

--- @param src string
--- @return boolean
local function has_symlink_attr(src)
    return (vim.fs.basename(src):match(symlink_pattern)) -- check if src starts with 'symlink_'
end

local function notify_stderr(_, data)
    if type(data) == "string" and data ~= "" then
        vim.notify(data, vim.log.levels.WARN, { title = "chezmoi.nvim" })
    end
end

--- @param tgt_files string[] | string
--- @param on_exit? fun(code: number, signal: number)
local function apply_tgt_files(tgt_files, on_exit)
    commands.apply({
        targets = tgt_files,
        args = { "--force", "--no-tty" },
        on_stderr = notify_stderr,
        on_exit = on_exit,
    })
end

--- @param src_files string[] | string
--- @param on_exit? fun(code: number, signal: number)
local function apply_src_files(src_files, on_exit)
    commands.apply({
        args = { "--no-tty", "--force", "--source-path", to_str(src_files) },
        on_stderr = notify_stderr,
        on_exit = on_exit,
    })
end

--- @param path string
--- @param dir string
--- @return boolean
local function is_path_inside_dir(path, dir)
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

--- @param file string|string[]?
--- @param on_exit? fun(code: number, signal: number)
--- @return string[]?
local function get_src_file(file, on_exit)
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

--- @return string?
local function get_src_dir()
    if cached_chezmoi_src_dir and cached_chezmoi_src_dir ~= "" then
        return cached_chezmoi_src_dir
    end

    local env = os.getenv("CHEZMOI_SOURCE_DIR")

    if env and env ~= "" then
        cached_chezmoi_src_dir = vim.fs.abspath(env)
        return cached_chezmoi_src_dir
    end

    local source_paths = get_src_file()

    if source_paths then
        cached_chezmoi_src_dir = source_paths[1]
        return cached_chezmoi_src_dir
    end

    return nil
end

--- @return boolean
local function is_src_file(file)
    local chezmoi_src_dir = get_src_dir()

    if not chezmoi_src_dir or chezmoi_src_dir == "" then
        return false
    end

    return is_path_inside_dir(file, chezmoi_src_dir)
end

--- @return boolean
local function should_ignore_src_file(file)
    if not file or file == "" then
        return false
    end

    local src_dir = get_src_dir()

    if not src_dir or src_dir == "" then
        return false
    end

    if not is_path_inside_dir(file, src_dir) then
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

--- @param files string|string[]
--- @param args string[]?
local function open_src_file(files, args)
    commands.edit({ targets = files, args = args or {} })
end

--- @return boolean
local function ask_open_src_file()
    return vim.fn.confirm("Open the chezmoi source file instead?\n", "&No\n&Yes", 1, "Question") == 2
end

--- @return boolean
local function ask_apply_to_tgt()
    return vim.fn.confirm("Apply to target now?\n", "&No\n&Yes", 1, "Question") == 2
end

local group = vim.api.nvim_create_augroup("chezmoi_auto_cmd", {
    clear = true,
})

vim.api.nvim_set_hl(0, "MiniStatuslineChezmoi", { bg = "#008080", bold = true })

local orig_active = statusline.active

---@diagnostic disable-next-line: duplicate-set-field
statusline.active = function()
    local result = orig_active()
    return result:gsub("%%=", statusline.section_chezmoi() .. "%%=", 1)
end

statusline.section_chezmoi = function()
    if not is_src_file(get_current_file()) then
        return ""
    end
    return CZM_STATUSLINE_HI
end

vim.api.nvim_create_autocmd("BufReadPre", {
    group = group,
    callback = function(args)
        local buf = args.buf

        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
                return
            end

            local buf_file = vim.api.nvim_buf_get_name(buf)
            if buf_file == "" or is_src_file(buf_file) then
                return
            end

            local sources_tbl = get_src_file(buf_file)

            if not sources_tbl or vim.tbl_isempty(sources_tbl) then
                return
            end

            local source = sources_tbl[1]

            if not source or not vim.uv.fs_lstat(source) or source == buf_file then
                return
            end

            if has_symlink_attr(source) then
                return
            end

            if ask_open_src_file() then
                open_src_file(buf_file)
            end
        end)
    end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,

    callback = function(args)
        local buf = args.buf
        if vim.bo[buf].buftype ~= "" then
            return
        end

        local buf_file = vim.api.nvim_buf_get_name(buf)
        if buf_file == "" or should_ignore_src_file(buf_file) then
            return
        end

        if not is_src_file(buf_file) then
            return
        end

        if ask_apply_to_tgt() then
            apply_src_files(buf_file)
            vim.notify("Applied to target", vim.log.levels.INFO, { title = "chezmoi.nvim" })
        end
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        local util = require("chezmoi.util")
        commands = require("chezmoi.commands")

        local function edit_complete(arg_lead, _, _)
            local completions = vim.fn.getcompletion(arg_lead, "file")
            for _, arg in ipairs({ "--watch", "--force" }) do
                if arg:find(arg_lead, 1, true) then
                    table.insert(completions, arg)
                end
            end
            return completions
        end

        vim.api.nvim_create_user_command("ChezmoiEdit", function(opts)
            local raw_args = opts.fargs

            local files, args = util.__classify_args(raw_args)

            if vim.tbl_isempty(files) then
                local buf_name = get_current_file()
                if not buf_name then
                    vim.notify("No valid file target detected", vim.log.levels.ERROR, { title = "ChezmoiEdit" })
                    return
                end
                files = { buf_name }
            end

            local bad_files = {}

            for _, file in ipairs(files) do
                local src_file = get_src_file(file)
                if not src_file or vim.tbl_isempty(src_file) then
                    table.insert(bad_files, file)
                end
            end

            if not vim.tbl_isempty(bad_files) then
                local files_str = table.concat(bad_files, "\n")
                vim.notify(
                    "Unable to open source for unmanaged files:\n" .. files_str,
                    vim.log.levels.WARN,
                    { title = "ChezmoiEdit" }
                )
                return
            end

            open_src_file(files, args)
        end, {
            nargs = "*",
            complete = edit_complete,
        })

        vim.api.nvim_create_user_command("ChezmoiApply", function(opts)
            local raw_args = opts.fargs
            local files, args = util.__classify_args(raw_args)

            if not vim.tbl_isempty(args) then
                vim.notify(
                    "File name cannot start with -. Escape with \\ if the file name contains a leading -.",
                    vim.log.levels.ERROR,
                    { title = "ChezmoiApply" }
                )
            end

            if vim.tbl_isempty(files) then
                local buf_name = get_current_file()
                if not buf_name then
                    vim.notify("No valid file target detected", vim.log.levels.ERROR, { title = "ChezmoiApply" })
                    return
                end
                files = { buf_name }
            end

            local target_files = {}
            local source_files = {}

            for _, file in ipairs(files) do
                if file:sub(1, 2) == "\\-" then
                    file = file:sub(2)
                end

                if is_src_file(file) then
                    table.insert(source_files, file)
                else
                    table.insert(target_files, file)
                end
            end

            if not vim.tbl_isempty(source_files) then
                apply_src_files(source_files, function(code, _)
                    if code == 0 then
                        vim.notify(
                            "Successfully applied " .. #source_files .. " source files.",
                            vim.log.levels.INFO,
                            { title = "ChezmoiApply" }
                        )
                    end
                end)
            end

            if not vim.tbl_isempty(target_files) then
                apply_tgt_files(target_files, function(code, _)
                    if code == 0 then
                        vim.notify(
                            "Successfully applied " .. #target_files .. " target files.",
                            vim.log.levels.INFO,
                            { title = "ChezmoiApply" }
                        )
                    end
                end)
            end
        end, {
            nargs = "*",
            complete = "file",
        })
    end,
})

vim.keymap.set("n", "<leader>zf", function()
    require("chezmoi.pick").telescope()
end, { desc = "Search che[Z]moi managed [F]iles" })

vim.keymap.set("n", "<leader>ze", "<cmd>ChezmoiEdit<CR>")
vim.keymap.set("n", "<leader>za", "<cmd>ChezmoiApply<CR>")
