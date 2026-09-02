local M = {}

local UT = require("config.utils")

--- @type fun(): ChezmoiEdit
local get_cmd_edit = UT.lazy_require("nvim-chezmoi.chezmoi.commands.edit")

--- Spawns `chezmoi edit` for one path. No UI, no state.
--- @param file string Absolute path to a target file.
--- @param on_exit fun(res: table?) Command result; may run in job context.
--- @return Job? job nil when the command failed to spawn.
function M.edit(file, on_exit) return get_cmd_edit():async(file, on_exit) end

return M
