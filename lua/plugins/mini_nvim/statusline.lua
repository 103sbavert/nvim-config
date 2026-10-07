local statusline = require("mini.statusline")

-- Set `use_icons` to true if you have a Nerd Font
statusline.setup({ use_icons = vim.g.have_nerd_font })

-- Configure the section for cursor location to LINE:COLUMN
--- @diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return "%2l:%-2v" end

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
