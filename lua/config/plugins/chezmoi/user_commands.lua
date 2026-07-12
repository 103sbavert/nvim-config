require("chezmoi")

local plugin_utils = require("chezmoi.util")

local utils = require("config.plugins.chezmoi.utils")
local common_utils = require("config.plugins.utils")

local group = vim.api.nvim_create_augroup("chezmoi_user_cmd", {
    clear = true,
})

--- Generates completion tracking vectors matched on active filesystem targets and subcommands.
--- @param arg_lead string Trailing data token matching target context for input expansion operations.
--- @return string[] Array listing of string path entries valid for UI matching selections.
local function edit_complete(arg_lead, _, _)
    local completions = vim.fn.getcompletion(arg_lead, "file")
    for _, arg in ipairs({ "--watch", "--force" }) do
        if arg:find(arg_lead, 1, true) then
            table.insert(completions, arg)
        end
    end
    return completions
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        vim.api.nvim_create_user_command("ChezmoiEdit", function(opts)
            local raw_args = opts.fargs

            local files, args = plugin_utils.__classify_args(raw_args)

            if vim.tbl_isempty(files) then
                local buf_name = common_utils.get_current_file()
                if not buf_name then
                    vim.notify("No valid file target detected", vim.log.levels.ERROR, { title = "ChezmoiEdit" })
                    return
                end
                files = { buf_name }
            end

            local bad_files = {}

            for _, file in ipairs(files) do
                local src_file = utils.get_src_file(file)
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

            utils.open_src_file(files, args)
        end, {
            nargs = "*",
            complete = edit_complete,
        })

        vim.api.nvim_create_user_command("ChezmoiApply", function(opts)
            local raw_args = opts.fargs
            local files, args = plugin_utils.__classify_args(raw_args)

            if not vim.tbl_isempty(args) then
                vim.notify(
                    "File name cannot start with -. Escape with \\ if the file name contains a leading -.",
                    vim.log.levels.ERROR,
                    { title = "ChezmoiApply" }
                )
            end

            if vim.tbl_isempty(files) then
                local buf_name = common_utils.get_current_file()
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

                if utils.is_src_file(file) then
                    table.insert(source_files, file)
                elseif utils.get_src_file(file) then
                    table.insert(target_files, file)
                end
            end

            if vim.tbl_isempty(source_files) and vim.tbl_isempty(target_files) then
                vim.notify("No chezmoi files to apply", vim.log.levels.INFO, { title = "ChezmoiApply" })
            end

            if not vim.tbl_isempty(source_files) then
                utils.apply_src_files(source_files, function(cmd_res, _)
                    if cmd_res.code and cmd_res.code == 0 then
                        vim.notify(
                            "Successfully applied " .. #source_files .. " source files.",
                            vim.log.levels.INFO,
                            { title = "ChezmoiApply" }
                        )
                    end
                end)
            end

            if not vim.tbl_isempty(target_files) then
                utils.apply_tgt_files(target_files, function(cmd_res, _)
                    if cmd_res.code and cmd_res.code == 0 then
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
