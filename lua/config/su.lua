local M = {}

function M.setup()
    local utils = require("config.utils")
    local await = utils.await
    local async_run = function(fn) utils.async_run(fn, { error_title = "Sudo" }) end

    local group =
        vim.api.nvim_create_augroup("SudoWritePlugin", { clear = true })

    local SUDO_STATUSLINE_HI = "%#StatuslineSudo# [sudo] %*"
    local statusline_initialized = false
    local orig_section_fileinfo

    local function init_sudo_hl()
        local vulgaris = require("bamboo.palette").vulgaris
        vim.api.nvim_set_hl(0, "StatuslineSudo", {
            fg = vulgaris.contrast,
            bg = vulgaris.red,
            bold = true,
        })
    end

    local function init_sudo_statusline(buf)
        init_sudo_hl()
        vim.b[buf].su_opened = true

        if not statusline_initialized then
            statusline_initialized = true
            local statusline = require("mini.statusline")
            orig_section_fileinfo = statusline.section_fileinfo

            --- @diagnostic disable-next-line: duplicate-set-field
            statusline.section_fileinfo = function(args)
                local fileinfo = orig_section_fileinfo(args)
                local current_buf = args.buf or vim.api.nvim_get_current_buf()

                if vim.b[current_buf] and vim.b[current_buf].su_opened then
                    return SUDO_STATUSLINE_HI .. " " .. fileinfo
                end

                return fileinfo
            end

            vim.schedule(function() vim.cmd("redrawstatus") end)
        end
    end

    --- @return boolean ok
    --- @return string? err
    local function write_to_temp_fd(buf)
        local temp_fd = vim.b[buf].su_temp_fd

        if not temp_fd then
            return false, "Temp file descriptor missing"
        end

        local fstat_err = await(vim.uv.fs_fstat, temp_fd)
        if fstat_err then
            return false, "Temp file descriptor invalid: " .. fstat_err
        end

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n") .. "\n"

        local trunc_err = await(vim.uv.fs_ftruncate, temp_fd, 0)
        if trunc_err then
            return false, "Failed to truncate temp file: " .. trunc_err
        end

        local write_err, bytes_written =
            await(vim.uv.fs_write, temp_fd, content, 0)
        if write_err then
            return false, "Failed to write temp file: " .. write_err
        end
        if not bytes_written or bytes_written < #content then
            return false,
                string.format(
                    "Incomplete write to temp file (%s/%s bytes)",
                    tostring(bytes_written),
                    #content
                )
        end

        local sync_err = await(vim.uv.fs_fsync, temp_fd)
        if sync_err then
            return false, "Failed to sync temp file: " .. sync_err
        end

        return true, nil
    end

    local function cleanup_on_exit(buf)
        vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
            group = group,
            buffer = buf,
            once = true,
            callback = function()
                local fd = vim.b[buf].su_temp_fd
                local path = vim.b[buf].su_temp_path

                if fd then
                    vim.uv.fs_close(fd, function(close_err)
                        if close_err then
                            vim.schedule(
                                function()
                                    vim.notify(
                                        "Failed to close temp file descriptor: "
                                            .. close_err,
                                        vim.log.levels.WARN,
                                        { title = "Sudo" }
                                    )
                                end
                            )
                        end
                    end)
                end

                if path then
                    vim.uv.fs_unlink(path, function(unlink_err)
                        if unlink_err then
                            vim.schedule(
                                function()
                                    vim.notify(
                                        "Failed to remove temp file "
                                            .. path
                                            .. ": "
                                            .. unlink_err,
                                        vim.log.levels.WARN,
                                        { title = "Sudo" }
                                    )
                                end
                            )
                        end
                    end)
                end
            end,
        })
    end

    --- @return integer temp_fd -1 on failure
    --- @return string? temp_path
    --- @return string? err
    local function make_tmp_file(buf, real_path)
        local existing_fd = vim.b[buf].su_temp_fd

        if existing_fd then
            local fstat_err = await(vim.uv.fs_fstat, existing_fd)

            if not fstat_err then
                return existing_fd, vim.b[buf].su_temp_path, nil
            end

            -- Stale fd/path (e.g. externally closed/deleted); drop cached
            -- state and fall through to create a fresh temp file.
            vim.b[buf].su_temp_fd = nil
            vim.b[buf].su_temp_path = nil
        end

        local filename = vim.fs.basename(real_path or "") or "file"
        local clean_name = filename:gsub("^%.+", ""):gsub("%.+$", "")
        if clean_name == "" then
            clean_name = "file"
        end

        local template = "/tmp/su." .. clean_name .. ".XXXXXX"
        local mkstemp_err, temp_fd, temp_path =
            await(vim.uv.fs_mkstemp, template)

        if mkstemp_err or not temp_fd or temp_fd < 0 then
            return -1, nil, (mkstemp_err or "unknown error")
        end

        vim.b[buf].su_temp_fd = temp_fd
        vim.b[buf].su_temp_path = temp_path
        return temp_fd, temp_path, nil
    end

    local function sudo_write(pass, buf)
        local real_path = vim.b[buf].su_real_path
        local temp_path = vim.b[buf].su_temp_path

        local cmd = {
            "sudo",
            "-S",
            "cp",
            "-f",
            temp_path,
            real_path,
        }

        local obj = await(vim.system, cmd, { stdin = pass .. "\n" })

        if obj.code ~= 0 then
            vim.notify(
                "Sudo write failed: " .. (obj.stderr or ""),
                vim.log.levels.ERROR,
                { title = "Sudo" }
            )
        else
            vim.notify(
                "Successfully saved " .. real_path,
                vim.log.levels.INFO,
                { title = "Sudo" }
            )

            vim.bo[buf].modified = false
        end
    end

    local function write_cmd(buf)
        async_run(function()
            local ok, err = write_to_temp_fd(buf)

            if not ok then
                vim.notify(
                    "Sudo write failed: " .. (err or "unknown error"),
                    vim.log.levels.ERROR,
                    { title = "Sudo" }
                )
                return
            end

            local pass = vim.fn.inputsecret(
                "Enter sudo password to save "
                    .. vim.b[buf].su_real_path
                    .. ": "
            )

            if pass and pass ~= "" then
                sudo_write(pass, buf)
            else
                vim.notify(
                    "Operation cancelled. No password provided.",
                    vim.log.levels.WARN,
                    { title = "Sudo" }
                )
            end
        end)
    end

    --- @return boolean
    local function is_path_writable(real_path)
        local stat_err, stat = await(vim.uv.fs_stat, real_path)

        if not stat_err and stat then
            local access_err, permission =
                await(vim.uv.fs_access, real_path, "w")
            return not access_err and permission == true
        end

        local parent_dir = vim.fs.dirname(real_path)
        if not parent_dir then
            return false
        end

        local access_err, permission = await(vim.uv.fs_access, parent_dir, "w")
        return not access_err and permission == true
    end

    vim.api.nvim_create_autocmd("BufReadPost", {
        group = group,
        callback = function(args)
            local buf = args.buf

            if vim.bo[buf].buftype ~= "" then
                return
            end

            if not vim.bo[buf].readonly then
                return
            end

            local real_path = utils.get_current_file(args)
            if not real_path then
                return
            end

            async_run(function()
                if is_path_writable(real_path) then
                    return
                end

                local should_root = vim.fn.confirm(
                    "This file is readonly on the file system. Open as root?\n",
                    "&Yes" .. "\n&No",
                    1
                ) == 1

                if not should_root then
                    return
                end

                local temp_fd, _, err = make_tmp_file(buf, real_path)

                if temp_fd < 0 then
                    vim.notify(
                        "Unable to create temp file in /tmp/\n" .. (err or ""),
                        vim.log.levels.ERROR,
                        { title = "Sudo" }
                    )

                    return
                end

                cleanup_on_exit(buf)
                local sudo_name = "sudo://" .. real_path
                pcall(vim.api.nvim_buf_set_name, buf, sudo_name)

                vim.b[buf].su_real_path = real_path
                vim.bo[buf].readonly = false
                vim.bo[buf].buftype = "acwrite"

                init_sudo_statusline(buf)

                -- Intercept writes for non-writable files
                vim.api.nvim_create_autocmd("BufWriteCmd", {
                    group = group,
                    buffer = buf,
                    callback = function() write_cmd(buf) end,
                })
            end)
        end,
    })
end

return M
