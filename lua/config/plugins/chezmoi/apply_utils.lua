local M = {}

local UT = require("config.utils")

--- @type fun(): ChezmoiApply
local get_cmd_apply = UT.lazy_require("nvim-chezmoi.chezmoi.commands.apply")

--- Spawns `chezmoi apply` for one path. No UI, no state, no classification.
--- @param file string Absolute path to a target or source file.
--- @param is_src boolean True when `file` is a chezmoi source path.
--- @param on_exit fun(res: table?) Command result; may run in job context.
--- @return Job? job nil when the command failed to spawn.
function M.apply(file, is_src, on_exit)
    local args
    if is_src then
        args = { "--source-path", file }
    else
        args = { file }
    end

    return get_cmd_apply():async(args, on_exit)
end

return M
