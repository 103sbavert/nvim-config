local CZM_STATUSLINE_HI = "%#MiniStatuslineChezmoi# [chezmoi] %*"
local chezmoi_utils = require("config.plugins.chezmoi.utils")
vim.api.nvim_set_hl(0, "MiniStatuslineChezmoi", { bg = "#1f9890", bold = true })

local UT = require("config.utils")
local statusline = require("mini.statusline")

-- Async cache: filepath -> boolean. Populated via autocmds so section_fileinfo stays sync.
local src_file_cache = {}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    callback = function(args)
        local buf_file = UT.get_current_file(args)
        if not buf_file then
            return
        end

        vim.uv.fs_stat(buf_file, function(_, stat_res)
            if not stat_res then
                return
            end
            chezmoi_utils.is_src_file(buf_file, function(is_src)
                src_file_cache[buf_file] = is_src
                vim.schedule(function() vim.cmd("redrawstatus") end)
            end)
        end)
    end,
})

-- Cache the original function to keep standard file info intact
local orig_section_fileinfo = statusline.section_fileinfo

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_fileinfo = function(args)
    local fileinfo = orig_section_fileinfo(args)
    local src_file = UT.get_current_file()

    if src_file and src_file ~= "" and src_file_cache[src_file] then
        return CZM_STATUSLINE_HI .. " " .. fileinfo
    end

    return fileinfo
end
