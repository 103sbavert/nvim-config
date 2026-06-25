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
local skip_paths = {}

local function normalize_path(path)
    if path == nil or path == "" then
        return nil
    end

    local resolved = vim.loop.fs_realpath(path)
    if resolved and resolved ~= "" then
        return resolved
    end

    return vim.fn.fnamemodify(path, ":p")
end

local function is_path_inside_dir(path, dir)
    local path_abs = normalize_path(path)
    local dir_abs = normalize_path(dir)

    if path_abs == nil or dir_abs == nil then
        return false
    end

    dir_abs = dir_abs:gsub("/+$", "")
    if path_abs == dir_abs then
        return true
    end

    return path_abs:sub(1, #dir_abs + 1) == (dir_abs .. "/")
end

local function source_path_for_target(file)
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

local function get_chezmoi_source_dir()
    if cached_chezmoi_src_dir ~= nil and cached_chezmoi_src_dir ~= "" then
        return cached_chezmoi_src_dir
    end

    local env_src_dir = os.getenv("CHEZMOI_SRC_DIR")
    if env_src_dir and env_src_dir ~= "" then
        cached_chezmoi_src_dir = normalize_path(env_src_dir)
        return cached_chezmoi_src_dir
    end

    local ok, source_paths = pcall(commands.source_path, {
        on_stderr = function() end,
    })

    if not ok or type(source_paths) ~= "table" then
        return nil
    end

    local source_root = source_paths[1]
    if type(source_root) ~= "string" or source_root == "" then
        return nil
    end

    cached_chezmoi_src_dir = normalize_path(source_root)
    return cached_chezmoi_src_dir
end

local function is_chezmoi_source_file(file)
    local chezmoi_src_dir = get_chezmoi_source_dir()
    if chezmoi_src_dir == nil or chezmoi_src_dir == "" then
        return false
    end

    return is_path_inside_dir(file, chezmoi_src_dir)
end

local function is_ignored_chezmoi_source(file_abs)
    if file_abs == nil or file_abs == "" then
        return false
    end

    local patterns = chezmoi_config.edit and chezmoi_config.edit.ignore_patterns or nil
    if type(patterns) ~= "table" then
        return false
    end

    for _, pattern in ipairs(patterns) do
        if type(pattern) == "string" and pattern ~= "" then
            local anchored_pattern = pattern
            if anchored_pattern:sub(-1) ~= "$" then
                anchored_pattern = anchored_pattern .. "$"
            end

            if file_abs:match(anchored_pattern) then
                return true
            end
        end
    end

    return false
end

local function open_chezmoi_source(file, source)
    source = source or source_path_for_target(file)
    if source == nil then
        return
    end

    skip_paths[source] = (skip_paths[source] or 0) + 1
    commands.edit({ targets = file })
end

local function show_chezmoi_prompt(file, source)
    local choice = vim.fn.confirm("Open the chezmoi source file instead?\n", "&No\n&Yes", 1, "Question")
    if choice == 2 then
        open_chezmoi_source(file, source)
    end
end

local function show_apply_prompt_for_source(source_abs)
    if source_abs == nil or source_abs == "" then
        return
    end

    local choice = vim.fn.confirm("Apply to target now?\n", "&No\n&Yes", 1, "Question")
    if choice ~= 2 then
        return
    end

    commands.apply({
        args = { "--no-tty", "--force", "--source-path", source_abs },
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

        if vim.bo[buf].buftype ~= "" then
            return
        end

        local file = vim.api.nvim_buf_get_name(buf)
        if file == "" then
            return
        end

        local file_abs = file
        if skip_paths[file_abs] and skip_paths[file_abs] > 0 then
            skip_paths[file_abs] = skip_paths[file_abs] - 1
            return
        end

        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            if vim.api.nvim_buf_get_name(buf) ~= file then
                return
            end

            if is_chezmoi_source_file(file) then
                return
            end

            local source = source_path_for_target(file)
            if source == nil then
                return
            end

            if source == file_abs then
                return
            end

            show_chezmoi_prompt(file, source)
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
        if file == "" then
            return
        end

        local file_abs = file

        if not is_chezmoi_source_file(file_abs) then
            return
        end

        if is_ignored_chezmoi_source(file_abs) then
            vim.notify(
                "Skipping chezmoi apply for ignored file: " .. vim.fn.fnamemodify(file, ":t"),
                vim.log.levels.INFO
            )
            return
        end

        show_apply_prompt_for_source(file_abs)
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        local util = require("chezmoi.util")
        local commands = require("chezmoi.commands")

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

        pcall(vim.api.nvim_del_user_command, "ChezmoiEdit")
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

        pcall(vim.api.nvim_del_user_command, "ChezmoiApply")
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
                if is_chezmoi_source_file(file) then
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
