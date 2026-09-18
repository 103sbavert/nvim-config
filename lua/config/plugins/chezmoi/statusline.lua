local CZM_STATUSLINE_HI = "%#MiniStatuslineChezmoi# [chezmoi] %*"

local highlight_initialized = false
local orig_section_fileinfo
local src_buf_cache = {}

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
        local fileinfo = orig_section_fileinfo(args)
        local current_buf = args.buf or vim.api.nvim_get_current_buf()

        if src_buf_cache[current_buf] then
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

        UT.async_run(function()
            local _, stat_res = UT.await(vim.uv.fs_stat, buf_file)
            if not stat_res then
                return
            end

            local is_src = UT.await(shared.is_src_file_async, buf_file)
            src_buf_cache[args.buf] = is_src

            if is_src then
                initialize_statusline()
                vim.cmd("redrawstatus")
            end
        end, { error_title = "Chezmoi" })
    end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(args) src_buf_cache[args.buf] = nil end,
})
