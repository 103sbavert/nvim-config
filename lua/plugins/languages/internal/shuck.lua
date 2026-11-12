local formatting = require("plugins.languages.internal.formatting")

local M = {}

--- @type string[]
M.filetypes = { "sh", "bash", "zsh" }

--- @type table<string, string>
local dialects = { bash = "bash", zsh = "zsh" }

--- Builds `shuck format` args for stdin formatting of the buffer in params.
--- @param params table none-ls params (bufnr, bufname, ft).
--- @return string[] args
function M.format_args(params)
    local name = params.bufname ~= "" and params.bufname
        or ("untitled." .. params.ft)

    local args = {
        "format",
        "--indent-style",
        "space",
        "--indent-width",
        tostring(formatting.get_indent(params.bufnr)),
        "--stdin-filename",
        name,
    }

    local dialect = dialects[params.ft]
    if dialect then
        vim.list_extend(args, { "--dialect", dialect })
    end
    table.insert(args, "-")
    return args
end

--- @type vim.lsp.Config
M.lsp_config = { filetypes = M.filetypes }

return M
