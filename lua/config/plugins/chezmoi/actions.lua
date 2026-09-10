local M = {}

local UT = require("config.utils")
local UI = require("config.plugins.chezmoi.ui")
local shared = require("config.plugins.chezmoi.utils")
local apply_cmd = require("config.plugins.chezmoi.apply_utils")
local edit_cmd = require("config.plugins.chezmoi.edit_utils")

--- Applies a file to its chezmoi target, with progress, exit inhibition and
--- notifications. Resolves whether the path is a source file unless told.
--- @param file string? Defaults to the current buffer's file.
--- @param opts? { quiet?: boolean, is_src?: boolean }
--- @param on_done? fun()
function M.apply(file, opts, on_done)
    opts = opts or {}
    file = file or vim.api.nvim_buf_get_name(0)

    if type(file) ~= "string" or file == "" then
        UI.notify_err("Filenames must be string")
        if on_done then
            on_done()
        end
        return
    end

    local progress = UT.progress("Applying...", { title = "Chezmoi" })

    --- @type Job?
    local job

    local dispose = UT.inhibit_exit(function() return job end, {
        on_wait = function() progress:step("Inhibiting exit...") end,
    })

    UT.async_run(function()
        local is_src = opts.is_src

        if is_src == nil then
            progress:step("Checking file...")
            is_src = UT.await(shared.is_src_file_async, file)
            progress:step("Applying...")
        end

        --- @type table?
        local res = UT.await(function(cb)
            job = apply_cmd.apply(file, is_src, cb)

            -- Nothing will call cb if the job never started.
            if not job then
                cb(nil)
            end
        end)

        dispose()
        progress:finish()

        if not opts.quiet then
            UI.notify_result(res, "Applied changes to target")
        end

        if on_done then
            on_done()
        end
    end, { error_title = "Chezmoi" })
end

--- Opens the chezmoi source file for a target, with progress and notifications.
--- @param file string? Defaults to the current buffer's file.
--- @param on_done? fun()
function M.edit(file, on_done)
    file = file or vim.api.nvim_buf_get_name(0)

    if type(file) ~= "string" or file == "" then
        UI.notify_err("Filenames must be string")
        if on_done then
            on_done()
        end
        return
    end

    local progress = UT.progress("Looking for source...", { title = "Chezmoi" })

    local job = edit_cmd.edit(file, function(res)
        progress:finish()
        UI.notify_result(res, "Opened source file")

        if on_done then
            on_done()
        end
    end)

    if not job then
        progress:finish()
        UI.notify_err("Failed to start chezmoi edit")

        if on_done then
            on_done()
        end
    end
end

return M
