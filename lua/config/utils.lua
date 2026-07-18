local M = {}

--- Resolves the absolute file system path of the current target buffer.
--- @param args table? Optional autocmd event payload parameters containing buffer context.
--- @return string? Absolute file path string if valid, otherwise nil.
function M.get_current_file(args)
    local buf_id = 0

    if args and args.buf then
        buf_id = args.buf
    end

    if not vim.api.nvim_buf_is_valid(buf_id) then
        return nil
    end

    local buf_name = vim.api.nvim_buf_get_name(buf_id)

    if not buf_name or buf_name == "" then
        return nil
    end

    return buf_name
end

--- Serializes a single string or an array of string arguments into a single space-separated sequence.
--- @param args string | string[] Input target arguments list or scalar value.
--- @return string Formatted plain text command-line string parameter.
function M.to_str(args)
    if type(args) == "table" then
        return table.concat(args, " ")
    end
    return args
end

--- Returns a function that calls require when invoked
--- @param modname string
--- @return fun(): any
function M.lazy_require(modname)
    return function() return require(modname) end
end

return M
