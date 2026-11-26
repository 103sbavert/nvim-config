local M = {}

function M.setup()
    local utils = require("config.utils")

    if vim.fn.executable("sudo") == 0 then
        vim.notify(
            "'sudo' executable not found on PATH, privileged writes are not possible for readonly files"
        )

        return
    end

    local await = utils.await
    local async_run = function(fn) utils.async_run(fn, { error_title = "Sudo" }) end

    local group =
        vim.api.nvim_create_augroup("SudoWritePlugin", { clear = true })

    local SUDO_STATUSLINE_HI = "%#StatuslineSudo# [sudo] %*"
    local statusline_initialized = false

    local function notify(msg, level) vim.notify(msg, level, { title = "Sudo" }) end

    local function init_sudo_statusline()
        if statusline_initialized then
            return
        end
        statusline_initialized = true

        local vulgaris = require("bamboo.palette").vulgaris
        vim.api.nvim_set_hl(0, "StatuslineSudo", {
            fg = vulgaris.contrast,
            bg = vulgaris.red,
            bold = true,
        })

        local statusline = require("mini.statusline")
        local orig_section_fileinfo = statusline.section_fileinfo

        --- @diagnostic disable-next-line: duplicate-set-field
        statusline.section_fileinfo = function(args)
            local fileinfo = orig_section_fileinfo(args)
            local current_buf = args.buf or vim.api.nvim_get_current_buf()

            if vim.b[current_buf].su_active then
                return SUDO_STATUSLINE_HI .. " " .. fileinfo
            end

            return fileinfo
        end
    end

    --- @return string? err
    local function write_file(path, content)
        local open_err, fd = await(vim.uv.fs_open, path, "w", 384)
        if open_err then
            return "Failed to open temp file: " .. open_err
        end

        local write_err, bytes_written = await(vim.uv.fs_write, fd, content, 0)
        local sync_err = not write_err and await(vim.uv.fs_fsync, fd) or nil
        vim.uv.fs_close(fd)

        if write_err then
            return "Failed to write temp file: " .. write_err
        end
        if not bytes_written or bytes_written < #content then
            return string.format(
                "Incomplete write to temp file (%s/%s bytes)",
                tostring(bytes_written),
                #content
            )
        end
        if sync_err then
            return "Failed to sync temp file: " .. sync_err
        end

        return nil
    end

    --- @param buf integer
    local function remove_temp(buf)
        local path = vim.b[buf].su_temp_path
        if not path then
            return
        end

        local ok, unlink_err = vim.uv.fs_unlink(path)
        vim.b[buf].su_temp_path = nil

        if not ok then
            notify(
                "Failed to remove temp file " .. path .. ": " .. unlink_err,
                vim.log.levels.WARN
            )
        end
    end

    --- @return "ok"|"cancel"|"error" status
    --- @return string? msg
    local function save(buf, real_path)
        local temp_path = vim.b[buf].su_temp_path

        if not temp_path then
            local mkstemp_err, fd, path =
                await(vim.uv.fs_mkstemp, "/tmp/su.XXXXXX")
            if mkstemp_err or not fd then
                return "error",
                    "Sudo write failed: " .. (mkstemp_err or "unknown error")
            end

            vim.uv.fs_close(fd)
            temp_path = path
            vim.b[buf].su_temp_path = path
        end

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local write_err =
            write_file(temp_path, table.concat(lines, "\n") .. "\n")
        if write_err then
            return "error", "Sudo write failed: " .. write_err
        end

        local pass = vim.fn.inputsecret(
            "Enter sudo password to save " .. real_path .. ": "
        )
        if pass == "" then
            return "cancel"
        end

        local obj = await(
            vim.system,
            { "sudo", "-k", "-S", "cp", "-f", temp_path, real_path },
            { stdin = pass .. "\n" }
        )
        if obj.code ~= 0 then
            return "error",
                "Sudo write failed, buffer still modified; :w to retry.\n"
                    .. vim.trim(obj.stderr or "")
        end

        return "ok"
    end

    local function write_cmd(buf)
        if vim.b[buf].su_pending then
            return
        end
        vim.b[buf].su_pending = true

        async_run(function()
            local real_path = utils.get_current_file({ buf = buf })
            local status, msg = save(buf, real_path)
            vim.b[buf].su_pending = nil

            if status == "ok" then
                vim.b[buf].su_active = true
                vim.bo[buf].readonly = false
                init_sudo_statusline()

                notify("Successfully saved " .. real_path, vim.log.levels.INFO)
                vim.bo[buf].modified = false
            elseif status == "cancel" then
                notify(
                    "Operation cancelled. No password provided.",
                    vim.log.levels.WARN
                )
            else
                notify(msg, vim.log.levels.ERROR)
            end
        end)
    end

    vim.api.nvim_create_autocmd("BufReadPost", {
        group = group,
        callback = function(args)
            local buf = args.buf

            if vim.bo[buf].buftype ~= "" then
                return
            end

            local real_path = utils.get_current_file(args)
            if not real_path or vim.uv.fs_access(real_path, "W") then
                return
            end

            vim.api.nvim_clear_autocmds({ group = group, buffer = buf }) -- clear old BufWriteCmds (in case `BufReadPost` is invoked a second time)
            vim.api.nvim_create_autocmd("BufWriteCmd", {
                group = group,
                buffer = buf,
                callback = function() write_cmd(buf) end,
            })

            vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
                group = group,
                buffer = buf,
                once = true,
                callback = function() remove_temp(buf) end,
            })
        end,
    })
end

return M
