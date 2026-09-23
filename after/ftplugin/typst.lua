local function resolve_filename(arg_filename)
    if arg_filename and arg_filename ~= "" then
        return arg_filename
    end
    return assert(
        require("config.utils").get_current_file(),
        "No file name provided"
    )
end

local function validate_filetype(filename, force)
    if force then
        return
    end
    local ft = vim.filetype.match({ filename = filename })
    assert(
        ft == "typst",
        string.format(
            "File %s is %s, typst expected\n(hint: terminate command with ! to skip detection)",
            filename,
            ft
        )
    )
end

local function resolve_output_path(filename, arg_outpath)
    local target_pdf = arg_outpath
        or (vim.fn.fnamemodify(filename, ":p:r") .. ".pdf")
    return vim.fn.fnamemodify(target_pdf, ":.")
end

local function notify_compile_result(out, outpath)
    if out.code == 0 then
        vim.notify(
            "Compiled to " .. outpath,
            vim.log.levels.INFO,
            { title = "Typst" }
        )
    else
        vim.notify(
            "Compilation failed:\n"
                .. (out.stderr ~= "" and out.stderr or "Unknown error"),
            vim.log.levels.ERROR,
            { title = "Typst" }
        )
    end
end

local function execute_typst_compile(filename, outpath)
    local compile_cmd = {
        "typst",
        "compile",
        filename,
        outpath,
    }

    vim.system(
        compile_cmd,
        {},
        vim.schedule_wrap(function(out) notify_compile_result(out, outpath) end)
    )
end

--- @param cmd_args vim.api.keyset.create_user_command.command_args args passed to the user cmd
local function compile_typst(cmd_args)
    assert(vim.fn.executable("typst") == 1, "Typst CLI not found")

    local filename = resolve_filename(cmd_args.fargs[1])
    validate_filetype(filename, cmd_args.bang)

    local outpath = resolve_output_path(filename, cmd_args.fargs[2])
    execute_typst_compile(filename, outpath)
end

vim.api.nvim_buf_create_user_command(0, "TypstCompile", compile_typst, {
    nargs = "*",
    complete = "file",
    desc = "Compile provided file (default to current buffer)",
})
