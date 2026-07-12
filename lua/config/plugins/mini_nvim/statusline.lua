local CZM_STATUSLINE_HI = "%#MiniStatuslineChezmoi# [chezmoi] %*"
local chezmoi_utils = require("config.plugins.chezmoi.utils")
local common_utils = require("config.plugins.utils")
local statusline = require("mini.statusline")

vim.api.nvim_set_hl(0, "MiniStatuslineChezmoi", { bg = "#1f9890", bold = true })

-- Set `use_icons` to true if you have a Nerd Font
statusline.setup({ use_icons = vim.g.have_nerd_font })

-- Configure the section for cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return "%2l:%-2v" end

-- Cache the original function to keep standard file info intact
local orig_section_fileinfo = statusline.section_fileinfo

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_fileinfo = function(args)
    local fileinfo = orig_section_fileinfo(args)
    local src_file = common_utils.get_current_file()

    if src_file and src_file ~= "" and chezmoi_utils.is_src_file(src_file) then
        return CZM_STATUSLINE_HI .. " " .. fileinfo
    end

    return fileinfo
end
