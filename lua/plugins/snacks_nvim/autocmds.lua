-- Sync disk modifications and refresh Snacks explorer
local refresh_files_grp =
    vim.api.nvim_create_augroup("SnacksRefreshFilesGroup", { clear = true })

local function refresh_explorer()
    if package.loaded["snacks"] then
        for _, picker in ipairs(Snacks.picker.get({ source = "explorer" })) do
            pcall(picker.find, picker)
        end
    end
end

vim.api.nvim_create_autocmd({ "TermClose", "TermLeave" }, {
    group = refresh_files_grp,
    callback = refresh_explorer,
})

vim.api.nvim_create_autocmd("FileType", {
    group = refresh_files_grp,
    pattern = { "gitcommit", "gitrebase" },
    callback = function(event)
        vim.api.nvim_create_autocmd("BufUnload", {
            group = refresh_files_grp,
            buffer = event.buf,
            once = true,
            callback = function() vim.schedule(refresh_explorer) end,
        })
    end,
})

-- Don't show hidden files if we're outside user home or if we're in one of the 'large dirs'
local snacks_hidden_file_grp =
    vim.api.nvim_create_augroup("SnacksHiddenFile", { clear = true })

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

local file_pickers = {
    "explorer",
    "files",
}

local function set_hidden(value)
    if
        Snacks == nil
        or Snacks.picker == nil
        or Snacks.picker.sources == nil
    then
        return
    end
    for _, p in ipairs(file_pickers) do
        local src = Snacks.picker.sources[p]
        if src ~= nil then
            src.hidden = value
        end
    end
end

local M = {}

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

vim.api.nvim_create_autocmd("DirChangedPre", {
    group = snacks_hidden_file_grp,
    pattern = { "window", "tabpage", "global" },
    callback = function(args) set_hidden(M.hidden_for_cwd(args.file)) end,
})

return M
