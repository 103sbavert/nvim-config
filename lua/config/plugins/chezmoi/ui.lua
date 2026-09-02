local M = {}

local TITLE = "Chezmoi"

--- Actionable prompt answers, shared by the confirm dialogs below.
--- Other returns (0 dismissed, 1 no) mean "do nothing" and are never compared.
--- @enum ChezmoiChoice
M.CHOICE = {
    yes = 2,
    never = 3,
    watch = 4,
}

--- @param msg string
function M.notify_ok(msg)
    vim.schedule(
        function() vim.notify(msg, vim.log.levels.INFO, { title = TITLE }) end
    )
end

--- @param msg string
function M.notify_err(msg)
    vim.schedule(
        function() vim.notify(msg, vim.log.levels.ERROR, { title = TITLE }) end
    )
end

--- Reports a chezmoi command result.
--- @param res table? Command result; nil is treated as success.
--- @param ok_msg string Message shown on success.
function M.notify_result(res, ok_msg)
    if not res or res.success then
        M.notify_ok(ok_msg)
    else
        M.notify_err(table.concat(res.data or {}))
    end
end

--- Prompts to apply the chezmoi source file to its target.
--- @param callback fun(choice: ChezmoiChoice)
function M.ask_apply(callback)
    callback(
        vim.fn.confirm(
            "Apply to the chezmoi target now?\n",
            "&no" .. "\n&yes" .. "\n&don't ask again" .. "\n&watch this file",
            1,
            "Question"
        )
    )
end

-- --- Prompts to open the chezmoi source file instead of the target.
-- --- @param callback fun(choice: ChezmoiChoice)
-- function M.ask_open(callback)
--     callback(
--         vim.fn.confirm(
--             "Open the chezmoi source file instead?\n",
--             "&no" .. "\n&yes" .. "\n&don't ask again",
--             1,
--             "Question"
--         )
--     )
-- end

return M
