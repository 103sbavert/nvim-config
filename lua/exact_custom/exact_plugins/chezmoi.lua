require("chezmoi").setup({
    edit = {
        watch = false,
        force = false,
        ignore_patterns = {
            "run_onchange_.*",
            "run_once_.*",
            "%.chezmoiignore",
            "%.chezmoitemplates?",
            "%.chezmoiscripts?",
            "%.chezmoidata",
            "%.gitignore",
            "%.internal",
            "%.git/.*",
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
local cached_chezmoi_src_dir = nil
local symlink_pattern = "^symlink_"

local function normalize_path(path)
    if not path or path == "" then
        return nil
    end
    return vim.fs.normalize(path)
end

local function source_has_symlink_attr(src)
    return (vim.fs.basename(src):match(symlink_pattern)) -- check if src starts with 'symlink_'
end

local function is_path_inside_dir(path, dir)
    local path_abs = normalize_path(path)
    local dir_abs = normalize_path(dir)

    if not path_abs or not dir_abs then
        return false
    end

    return path_abs:find(dir_abs, 1, true) == 1
end

local function get_source_file_path(file)
    local ok, source_paths = pcall(commands.source_path, {
        targets = file,
        on_stderr = function() end,
    })

    if not ok or type(source_paths) ~= "table" then
        return nil
    end

    local source = source_paths[1]
    if type(source) ~= "string" or source == "" then
        return nil
    end

    return normalize_path(source)
end

local function get_source_dir()
    if cached_chezmoi_src_dir and cached_chezmoi_src_dir ~= "" then
        return cached_chezmoi_src_dir
    end

    local env = os.getenv("CHEZMOI_SOURCE_DIR")
    if env and env ~= "" then
        cached_chezmoi_src_dir = normalize_path(env)
        return cached_chezmoi_src_dir
    end

    local ok, source_paths = pcall(commands.source_path, {
        on_stderr = function() end,
    })

    if ok and type(source_paths) == "table" and type(source_paths[1]) == "string" and source_paths[1] ~= "" then
        cached_chezmoi_src_dir = normalize_path(source_paths[1])
        return cached_chezmoi_src_dir
    end

    return nil
end

local function is_source_file(file)
    local chezmoi_src_dir = get_source_dir()
    if not chezmoi_src_dir or chezmoi_src_dir == "" then
        return false
    end

    return is_path_inside_dir(file, chezmoi_src_dir)
end

local function is_source_file_ignored(file)
    if not file or file == "" then
        return false
    end

    local patterns = chezmoi_config.edit and chezmoi_config.edit.ignore_patterns
    if type(patterns) ~= "table" then
        return false
    end

    for _, pattern in ipairs(patterns) do
        if type(pattern) == "string" and pattern ~= "" then
            local anchored_pattern = pattern
            if anchored_pattern:sub(-1) ~= "$" then
                anchored_pattern = anchored_pattern .. "$"
            end

            if file:match(anchored_pattern) then
                return true
            end
        end
    end

    return false
end

local function open_source_file(file)
    commands.edit({ targets = file })
end

local function show_open_source_file_prompt(file)
    local choice = vim.fn.confirm("Open the chezmoi source file instead?\n", "&No\n&Yes", 1, "Question")
    if choice == 2 then
        open_source_file(file)
    end
end

local function show_apply_to_target_file_prompt(source)
    if not source or source == "" then
        return
    end

    local choice = vim.fn.confirm("Apply to target now?\n", "&No\n&Yes", 1, "Question")
    if choice ~= 2 then
        return
    end

    commands.apply({
        args = { "--no-tty", "--force", "--source-path", source },
        on_stderr = function(_, data)
            if type(data) == "string" and data ~= "" then
                vim.notify(data, vim.log.levels.WARN)
            end
        end,
    })
end

local group = vim.api.nvim_create_augroup("chezmoi-open-source-prompt", {
    clear = true,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(args)
        local buf = args.buf

        if vim.b[buf].chezmoi_checked then
            return
        end

        vim.b[buf].chezmoi_checked = true

        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
                return
            end

            local file = vim.api.nvim_buf_get_name(buf)
            if file == "" or is_source_file(file) then
                return
            end

            local source = get_source_file_path(file)
            if not source or source == file then
                return
            end

            if not source_has_symlink_attr(source) then
                show_open_source_file_prompt(file)
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

        local file = vim.api.nvim_buf_get_name(buf)
        if file == "" or is_source_file_ignored(file) then
            return
        end

        if not is_source_file(file) then
            return
        end

        show_apply_to_target_file_prompt(file)
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        local util = require("chezmoi.util")
        commands = require("chezmoi.commands")

        local function current_file(command_name)
            local bufname = vim.api.nvim_buf_get_name(0)
            if bufname == "" or vim.bo.buftype ~= "" then
                vim.notify(command_name .. ": No valid file target detected", vim.log.levels.ERROR)
                return nil
            end
            return bufname
        end

        local function apply_stderr(_, data)
            if type(data) == "string" and data ~= "" then
                vim.notify(data, vim.log.levels.WARN)
            end
        end

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
            local fargs = opts.fargs
            local targets = select(1, util.__classify_args(fargs))

            if vim.tbl_isempty(targets) then
                local bufname = current_file("ChezmoiEdit")
                if not bufname then
                    return
                end

                fargs = vim.list_extend({ bufname }, fargs)
            end

            local parsed_targets, parsed_args = util.__classify_args(fargs)
            commands.edit({
                targets = parsed_targets,
                args = parsed_args,
            })
        end, {
            nargs = "*",
            complete = edit_complete,
        })

        vim.api.nvim_create_user_command("ChezmoiApply", function(opts)
            local files = opts.fargs

            if #files == 0 then
                local bufname = current_file("ChezmoiApply")
                if not bufname then
                    return
                end
                files = { bufname }
            end

            for _, file in ipairs(files) do
                if file:sub(1, 1) == "-" then
                    vim.notify("ChezmoiApply: flags not supported; only filenames allowed", vim.log.levels.ERROR)
                    return
                end
            end

            local target_files = {}

            for _, file in ipairs(files) do
                if is_source_file(file) then
                    commands.apply({
                        args = { "--no-tty", "--source-path", file },
                        on_stderr = apply_stderr,
                    })
                else
                    table.insert(target_files, file)
                end
            end

            if not vim.tbl_isempty(target_files) then
                commands.apply({
                    targets = target_files,
                    args = { "--no-tty" },
                    on_stderr = apply_stderr,
                })
            end
        end, {
            nargs = "*",
            complete = "file",
        })
    end,
})

vim.keymap.set("n", "<leader>sz", function()
    require("chezmoi.pick").telescope()
end, { desc = "[S]earch che[Z]moi managed files" })
