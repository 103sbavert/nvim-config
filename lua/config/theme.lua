vim.pack.add({ gh("ribru17/bamboo.nvim") })

local c = require("bamboo.palette")["vulgaris"]
local util = require("bamboo.util")

local bg1 = util.darken(c.bg1, 0.03)
local bg2 = util.darken(c.bg2, 0.03)
local bg3 = util.darken(c.bg3, 0.03)

local hl_write = util.blend(bg1, c.blue, 0.2)
local hl_read = util.blend(bg1, c.green, 0.1)
local hl_text = util.blend(bg1, c.green, 0.1)

-- Dap sign highlights
local hl_dap_breakpoint_text = util.darken(c.coral, 0.35)
local hl_dap_stopped_text = util.darken(c.orange, 0.35)
local hl_dap_breakpoint_rejected = util.darken(c.yellow, 0.35)

-- Line HL
local hl_dap_stopped_line = util.darken(c.orange, 0.85, bg1)

require("bamboo").setup({
    style = "vulgaris",
    transparent = false,
    term_colors = true,
    code_style = {
        comments = { italic = true },
        keywords = { italic = true },
        diagnostics = {
            darker = true,
            undercurl = true,
            background = true,
        },
    },
    dim_inactive = true,
    colors = {
        bg1 = bg1,
        bg2 = bg2,
        bg3 = bg3,
    },
    highlights = {
        NormalFloat = { bg = c.bg_d },
        FloatBorder = { fg = c.purple },
        -- LSP highlights
        LspReferenceWrite = { bg = hl_write },
        LspReferenceRead = { bg = hl_read },
        LspReferenceText = { bg = hl_text },
        -- Noice Popup highlights
        NoiceConfirm = { link = "NormalFloat" },
        NoiceConfirmBorder = { link = "FloatBorder" },
        -- Dap sign highlights
        DapBreakpoint = { fg = hl_dap_breakpoint_text },
        DapBreakpointRejected = { fg = hl_dap_breakpoint_rejected },
        DapStopped = { fg = hl_dap_stopped_text },
        DapStoppedLine = { bg = hl_dap_stopped_line },
    },
})

require("bamboo").load()
