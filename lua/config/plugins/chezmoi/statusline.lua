local CZM_STATUSLINE_HI = "%#MiniStatuslineChezmoi# [chezmoi] %*"

local highlight_initialized = false
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
    local og_fileinfo_cb = statusline.section_fileinfo

    --- @diagnostic disable-next-line: duplicate-set-field
    statusline.section_fileinfo = function(args)
        local bufnr = (args and args.buf) or vim.api.nvim_get_current_buf()
        if bufnr == 0 then
            bufnr = vim.api.nvim_get_current_buf()
        end

        local og_fileinfo = og_fileinfo_cb(args)

        if src_buf_cache[bufnr] then
            return CZM_STATUSLINE_HI .. " " .. og_fileinfo
        end
        return og_fileinfo
    end
end

local function detect_czm_src(args)
    local bufnr = args and args.buf
    if not bufnr or bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end

    if src_buf_cache[bufnr] ~= nil then
        return
    end

    local UT = require("config.utils")
    local bufname = UT.get_current_file({ buf = bufnr })
    if not bufname then
        src_buf_cache[bufnr] = false
        return
    end

    UT.async_run(function()
        local shared = require("config.plugins.chezmoi.utils")
        local is_src = shared.is_src_file_async(bufname)
        src_buf_cache[bufnr] = is_src and true or false

        initialize_statusline()
    end, { error_title = "Chezmoi statusline async detection" })
end

local chezmoi_src_cache_grp =
    vim.api.nvim_create_augroup("ChezmoiStatuslineGroup", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    group = chezmoi_src_cache_grp,
    callback = function(args) detect_czm_src(args) end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
    group = chezmoi_src_cache_grp,
    callback = function(args) src_buf_cache[args.buf] = nil end,
})

detect_czm_src({ buf = vim.api.nvim_get_current_buf() })
