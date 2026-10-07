local CTRL_V = vim.api.nvim_replace_termcodes("<C-V>", true, true, true)
local CTRL_S = vim.api.nvim_replace_termcodes("<C-S>", true, true, true)
local DEFAULT_LOC = "%2l:%-2v"

local statusline = require("mini.statusline")

-- Set `use_icons` to true if you have a Nerd Font
statusline.setup({ use_icons = vim.g.have_nerd_font })

-- Configure the section for cursor location:
-- default: LINE:COLUMN
-- visual, block visual and selection: show range as START:STARTCOL-END:ENDCOL
-- line-visual and line-select: START-END

--- @diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
    local mode = vim.fn.mode()

    -- map Select modes to their Visual equivalent;
    -- getregionpos() only accepts visual types
    local vmode = mode == "s" and "v"
        or mode == "S" and "V"
        or mode == CTRL_S and CTRL_V
        or mode

    -- fall back in non-visual-like modes
    if not (vmode == "v" or vmode == "V" or vmode == CTRL_V) then
        return DEFAULT_LOC
    end

    -- getpos('v') + getpos('.') gets the selection coordinates, normalized
    -- by getregionpos
    local region = vim.fn.getregionpos(
        vim.fn.getpos("v"),
        vim.fn.getpos("."),
        { type = vmode }
    )

    if not (region and #region > 0) then
        return DEFAULT_LOC
    end

    local s = region[1][1]
    local e = region[#region][2]

    if vmode == "V" then
        if s[2] == e[2] then
            return string.format("%2d", s[2])
        end
        return string.format("%d-%d", s[2], e[2])
    end

    return string.format("%d:%d-%d:%d", s[2], s[3], e[2], e[3])
end

-- Show a macro-recording indicator in the mode section. Nvim's own
-- "recording @x" message is silently dropped when 'cmdheight' is 0 (no
-- cmdline row to draw it in), so mini.statusline needs its own indicator.
local orig_section_mode = statusline.section_mode

--- @diagnostic disable-next-line: duplicate-set-field
statusline.section_mode = function(args)
    local record_reg = vim.fn.reg_recording()
    if record_reg ~= "" then
        return "REC @" .. record_reg, "MiniStatuslineModeReplace"
    end
    return orig_section_mode(args)
end
