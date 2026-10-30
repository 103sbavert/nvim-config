local M = {}

local function get_clean_stdpath(varname)
    local v = os.getenv(varname)
    if not v or v == "" then
        return nil
    end
    local s = v:gsub("/+$", "")
    return s == "" and "/" or s
end

local home = get_clean_stdpath("HOME")
local function xdg(varname, fallback_suffix)
    return get_clean_stdpath(varname)
        or (home and home .. fallback_suffix or nil)
end

local large_dirs = {
    home,
    xdg("XDG_CONFIG_HOME", "/.config"),
    xdg("XDG_STATE_HOME", "/.local/state"),
    xdg("XDG_DATA_HOME", "/.local/share"),
    xdg("XDG_CACHE_HOME", "/.cache"),
}

--- Returns the picker `hidden` value for a directory.
--- `true` shows hidden files, `false` hides them.
function M.hidden_for_cwd(raw)
    if raw == nil or raw == "" or home == nil then
        return true
    end

    local s = raw:gsub("/+$", "")
    local cwd = s == "" and "/" or s

    if vim.fs.relpath(home, cwd) == nil then
        return false
    end

    for _, d in ipairs(large_dirs) do
        if cwd == d then
            return false
        end
    end

    return true
end

--- Wraps `snacks.picker.source.lsp.request` to display a spinner
--- notification while awaiting the LSP response.
---@param original_lsp_request fun(buf: integer, method: string, params: table, cb: fun(...)): any
---@return fun(buf: integer, method: string, params: table, cb: fun(...)): any
function M.custom_lsp_request(original_lsp_request)
    return function(buf, method, params, cb)
        local spinner_id = "await_lsp_" .. tostring(buf) .. method

        vim.schedule(function()
            Snacks.notifier.notify("Waiting for LSP", "info", {
                id = spinner_id,
                title = "Snacks picker",
                timeout = false,
                opts = function(notif) notif.icon = Snacks.util.spinner() end,
            })
        end)

        original_lsp_request(buf, method, params, cb)

        vim.schedule(function() Snacks.notifier.hide(spinner_id) end)
    end
end

--- Wraps `snacks.picker.source.explorer.explorer` so the tree view is only
--- used while the filter is empty. The user preference is kept in `tree_pref`.
--- @param original fun(opts: table, ctx: table): any
--- @return fun(opts: table, ctx: table): any
function M.explorer_tree_finder(original)
    return function(opts, ctx)
        local p = ctx.picker
        if p.tree_pref == nil then
            p.tree_pref = opts.tree
        end

        local tree = p.tree_pref and ctx.filter:is_empty()
        opts.tree = tree
        opts.formatters.file.filename_only = tree

        return original(opts, ctx)
    end
end

--- Toggles the stored explorer tree preference and refreshes the picker.
--- @param p snacks.Picker
function M.explorer_toggle_tree(p)
    local cur = p.tree_pref
    if cur == nil then
        ---@diagnostic disable-next-line: undefined-field explorer opts defines it
        cur = p.opts.tree
    end
    ---@diagnostic disable-next-line: inject-field
    p.tree_pref = not cur

    p:refresh()
end

return M
