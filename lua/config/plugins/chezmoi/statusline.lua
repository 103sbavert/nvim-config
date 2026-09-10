local CZM_STATUSLINE_HI = "%#MiniStatuslineChezmoi# [chezmoi] %*"

local highlight_initialized = false
local orig_section_fileinfo
local src_file_cache = {}

local function initialize_statusline()
    if highlight_initialized then
        return
    end
    highlight_initialized = true

    local vulgaris = require("bamboo.palette").vulgaris
    vim.api.nvim_set_hl(
        0,
        "MiniStatuslineChezmoi",
        { fg = vulgaris.contrast, bg = vulgaris.purple, bold = true }
    )

    local statusline = require("mini.statusline")
    orig_section_fileinfo = statusline.section_fileinfo

    --- @diagnostic disable-next-line: duplicate-set-field
    statusline.section_fileinfo = function(args)
        local UT = require("config.utils")
        local fileinfo = orig_section_fileinfo(args)
        local src_file = UT.get_current_file()

        if src_file and src_file ~= "" and src_file_cache[src_file] then
            return CZM_STATUSLINE_HI .. " " .. fileinfo
        end

        return fileinfo
    end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    callback = function(args)
        local UT = require("config.utils")
        local shared = require("config.plugins.chezmoi.utils")

        local buf_file = UT.get_current_file(args)
        if not buf_file then
            return
        end

        vim.uv.fs_stat(buf_file, function(_, stat_res)
            if not stat_res then
                return
            end
            shared.is_src_file_async(buf_file, function(is_src)
                src_file_cache[buf_file] = is_src
                if is_src then
                    vim.schedule(function()
                        initialize_statusline()
                        vim.cmd("redrawstatus")
                    end)
                end
            end)
        end)
    end,
})
