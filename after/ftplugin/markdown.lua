local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = 0, desc = desc })
end

map(
    "n",
    "gx",
    "<cmd>Mdn inline_link open<CR>",
    "Open inline link URI under cursor"
)
map(
    "n",
    "gf",
    "<cmd>Mdn wikilink follow<CR>",
    "Open markdown file from WikiLink"
)
map(
    "n",
    "gF",
    "<cmd>Mdn wikilink follow_hor<CR>",
    "Open markdown file from WikiLink in a horizontal split"
)
map(
    "n",
    "<leader>mr",
    "<cmd>Mdn wikilink find_references<CR>",
    "Show references of WikiLink or current buffer"
)
map(
    "n",
    "<leader>ln",
    "<cmd>Mdn wikilink rename_references<CR>",
    "Rename references of WikiLink or current buffer"
)
map(
    "n",
    "<C-o>",
    "<cmd>Mdn history go_back<CR>",
    "Go back to previously visited Markdown buffer"
)
map(
    "n",
    "<C-S-o>",
    "<cmd>Mdn history go_forward<CR>",
    "Go to next visited Markdown buffer"
)

-- markdown specific keybinds
map(
    { "n", "v" },
    "<leader>mb",
    "<cmd>Mdn formatting strong_toggle<CR>",
    "Toggle strong formatting"
)
map(
    { "n", "v" },
    "<leader>mi",
    "<cmd>Mdn formatting emphasis_toggle<CR>",
    "Toggle emphasis formatting"
)
map(
    { "n", "v" },
    "<leader>mt",
    "<cmd>Mdn formatting task_list_toggle<CR>",
    "Toggle task list status"
)
map(
    { "n", "v" },
    "<leader>mk",
    "<cmd>Mdn inline_link toggle<CR>",
    "Toggle inline link"
)

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
        ft == "markdown",
        string.format(
            "File %s is %s, markdown expected\n(hint: terminate command with ! to skip detection)",
            filename,
            ft
        )
    )
end

local function resolve_output_path(filename, arg_outpath)
    local target_file = arg_outpath
        or (vim.fn.fnamemodify(filename, ":p:r") .. ".pdf")
    return vim.fn.fnamemodify(target_file, ":.")
end

local function notify_compile_result(out, outpath)
    if out.code == 0 then
        vim.notify(
            "Compiled to " .. outpath,
            vim.log.levels.INFO,
            { title = "Pandoc" }
        )
    else
        vim.notify(
            "Compilation failed:\n"
                .. (out.stderr ~= "" and out.stderr or "Unknown error"),
            vim.log.levels.ERROR,
            { title = "Pandoc" }
        )
    end
end

local function execute_pandoc_compile(filename, outpath)
    local md_flavor = vim.g.pandoc_md_flavor or "gfm"
    local pdf_engine = vim.g.pandoc_pdf_engine or "typst"

    local compile_cmd = {
        "pandoc",
        "--from=" .. md_flavor,
        "--pdf-engine=" .. pdf_engine,
        filename,
        "-o",
        outpath,
    }

    vim.system(
        compile_cmd,
        {},
        vim.schedule_wrap(function(out) notify_compile_result(out, outpath) end)
    )
end

--- @param cmd_args vim.api.keyset.create_user_command.command_args args passed to the user cmd
local function compile_markdown(cmd_args)
    assert(vim.fn.executable("pandoc") == 1, "Pandoc CLI not found")

    local filename = resolve_filename(cmd_args.fargs[1])
    validate_filetype(filename, cmd_args.bang)

    local outpath = resolve_output_path(filename, cmd_args.fargs[2])
    execute_pandoc_compile(filename, outpath)
end

vim.api.nvim_buf_create_user_command(0, "PandocCompile", compile_markdown, {
    nargs = "*",
    complete = "file",
    desc = "Compile provided Markdown file using Pandoc with GFM reader",
})
