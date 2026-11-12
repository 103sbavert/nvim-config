local M = {}

local CTRL_V = require("config.utils").CTRL_V
local CTRL_S = require("config.utils").CTRL_S

--- @type table<string, string>
local ft_formatters = {
    typst = "tinymist",
    sh = "null-ls", -- none-ls source: shuck_format (stdin, get_indent)
    bash = "null-ls", -- none-ls source: shuck_format (stdin, get_indent)
    zsh = "null-ls", -- none-ls source: shuck_format (stdin, get_indent)
    javascript = "null-ls", -- none-ls source: prettier
    typescript = "null-ls", -- none-ls source: prettier
    javascriptreact = "null-ls", -- none-ls source: prettier
    typescriptreact = "null-ls", -- none-ls source: prettier
    json = "null-ls", -- none-ls source: prettier
    jsonc = "null-ls", -- none-ls source: prettier
    css = "null-ls", -- none-ls source: prettier
    graphql = "null-ls", -- none-ls source: prettier
    markdown = "null-ls", -- none-ls source: prettier
    yaml = "null-ls", -- none-ls source: prettier
    python = "null-ls", -- none-ls source: isort
    go = "null-ls", -- none-ls source: goimports, gofumpt
    lua = "null-ls", -- none-ls source: stylua
}
local VISUAL_LIKE_MODES = { "v", "V", "s", "S", CTRL_V, CTRL_S }

--- @param range? table
--- @return integer? start_line, integer? end_line
local function caller_range(range)
    if range and range.start_line and range.end_line then
        return range.start_line, range.end_line
    end
end

--- @return integer? start_line, integer? end_line
local function visual_range()
    if not vim.tbl_contains(VISUAL_LIKE_MODES, vim.fn.mode()) then
        return
    end

    local a = vim.fn.getpos("v")[2]
    local b = vim.fn.getpos(".")[2]
    return math.min(a, b), math.max(a, b)
end

--- @return integer? start_line, integer? end_line
local function formatexpr_range()
    if vim.v.lnum > 0 and vim.v.count > 0 then
        return vim.v.lnum, vim.v.lnum + vim.v.count - 1
    end
end

--- Formats bufnr, optionally asynchronously. If selection ranges are present,
--- only formats the selecton.
--- @param bufnr? integer Buffer to format (Default: current buffer)
--- @param async? boolean Whether to format asynchronously (default: false)
--- @param range? table Buffer range to format (Default: auto-detected)
function M.FormatBuffer(bufnr, async, range)
    async = async == true
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    local format_opts = {
        bufnr = bufnr,
        async = async,
        name = ft_formatters[vim.bo[bufnr].filetype],
        formatting_options = {
            tabSize = M.get_indent(bufnr),
            insertSpaces = vim.bo[bufnr].expandtab,
        },
    }

    local start_line, end_line = caller_range(range)
    if not (start_line and end_line) then
        start_line, end_line = visual_range()
    end
    if not (start_line and end_line) then
        start_line, end_line = formatexpr_range()
    end

    if start_line and end_line then
        format_opts.range = {
            ["start"] = { start_line, 0 },
            ["end"] = { end_line, #vim.fn.getline(end_line) },
        }
    end

    vim.lsp.buf.format(format_opts)
end

--- Returns effective indent size for bufnr: buffer-local shiftwidth (or tabstop
--- when shiftwidth=0), cascading to global, with 4 as final safety fallback.
--- @param bufnr integer The buffer handle/number to evaluate.
--- @return integer indent_size The resolved shiftwidth or tabstop indent level.
function M.get_indent(bufnr)
    local sw = vim.bo[bufnr].shiftwidth
    if sw ~= 0 then
        return sw
    end
    -- shiftwidth=0 means "use tabstop"
    local ts = vim.bo[bufnr].tabstop
    if ts ~= 0 then
        return ts
    end
    return 4
end

return M
