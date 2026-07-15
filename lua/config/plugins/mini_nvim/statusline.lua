local CZM_STATUSLINE_HI = "%#MiniStatuslineChezmoi# [chezmoi] %*"
local common_utils = require("config.utils")
local statusline = require("mini.statusline")

vim.api.nvim_set_hl(0, "MiniStatuslineChezmoi", { bg = "#1f9890", bold = true })

-- Set `use_icons` to true if you have a Nerd Font
statusline.setup({ use_icons = vim.g.have_nerd_font })

-- Configure the section for cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return "%2l:%-2v" end

-- Async cache: filepath -> boolean. Populated via autocmds so section_fileinfo stays sync.
local src_file_cache = {}

-- Lazy-load chezmoi utils to avoid requiring them before nvim-chezmoi is ready.
local chezmoi_utils = nil
local function get_chezmoi_utils()
    if not chezmoi_utils then
        local ok, m = pcall(require, "config.plugins.chezmoi.utils")
        if ok then chezmoi_utils = m end
    end
    return chezmoi_utils
end

local function update_src_cache(file)
    if not file or file == "" then return end
    local utils = get_chezmoi_utils()
    if not utils then return end
    utils.is_src_file(file, function(is_src)
        src_file_cache[file] = is_src
        vim.schedule(function() vim.cmd("redrawstatus") end)
    end)
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    callback = function() update_src_cache(common_utils.get_current_file()) end,
})

-- Cache the original function to keep standard file info intact
local orig_section_fileinfo = statusline.section_fileinfo

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_fileinfo = function(args)
    local fileinfo = orig_section_fileinfo(args)
    local src_file = common_utils.get_current_file()

    if src_file and src_file ~= "" and src_file_cache[src_file] then
        return CZM_STATUSLINE_HI .. " " .. fileinfo
    end

    return fileinfo
end
