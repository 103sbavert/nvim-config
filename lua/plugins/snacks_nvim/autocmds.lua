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

local file_pickers = {
    "explorer",
    "files",
}

local function set_hidden(value)
    if
        Snacks == nil
        or Snacks.config == nil
        or Snacks.config.picker == nil
        or Snacks.config.picker.sources == nil
    then
        return
    end
    for _, p in ipairs(file_pickers) do
        local src = Snacks.config.picker.sources[p]
        if src ~= nil then
            --- @diagnostic disable-next-line: inject-field
            src.hidden = value
        end
    end
end

vim.api.nvim_create_autocmd("DirChanged", {
    group = snacks_hidden_file_grp,
    pattern = { "window", "tabpage", "global" },
    callback = function(args)
        set_hidden(
            require("plugins.snacks_nvim.utils").hidden_for_cwd(args.file)
        )
    end,
})
