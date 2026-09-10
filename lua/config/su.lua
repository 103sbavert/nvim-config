local M = {}

function M.setup()
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

    local function write_buf_to_fd(buf, fd)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n") .. "\n"

        vim.uv.fs_ftruncate(fd, 0)
        vim.uv.fs_write(fd, content, 0)
        vim.uv.fs_fsync(fd)
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
                    pcall(vim.uv.fs_close, fd)
                end
                if path then
                    pcall(vim.uv.fs_unlink, path)
                end
            end,
        })
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

        vim.system(cmd, { stdin = pass .. "\n" }, function(obj)
            vim.schedule(function()
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
            end)
        end)
    end

    local function write_cmd(buf)
        local temp_fd = vim.b[buf].su_temp_fd
        local real_path = vim.b[buf].su_real_path

        if not temp_fd then
            local template = "/tmp/neovim_sudo.XXXXXX"
            local temp_path, err
            temp_fd, temp_path, err = vim.uv.fs_mkstemp(template)

            if not temp_fd or err then
                vim.notify(
                    "Unable to create temp file in /tmp/\n" .. (err or ""),
                    vim.log.levels.ERROR,
                    { title = "Sudo" }
                )
                return
            end

            vim.b[buf].su_temp_fd = temp_fd
            vim.b[buf].su_temp_path = temp_path
            cleanup_on_exit(buf)
        end

        write_buf_to_fd(buf, temp_fd)

        local pass = vim.fn.inputsecret(
            "Enter sudo password to save " .. real_path .. ": "
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

            local real_path = require("config.utils").get_current_file(args)
            if not real_path then
                return
            end

            --- @type boolean
            local is_writable
            local stat = vim.uv.fs_stat(real_path)

            if stat then
                is_writable, _, _ = vim.uv.fs_access(real_path, "w") or false
            else
                local parent_dir = vim.fs.dirname(real_path)
                is_writable, _, _ = parent_dir
                        and vim.uv.fs_access(parent_dir, "w")
                    or false
            end

            if is_writable then
                return
            end

            vim.schedule(function()
                local should_root = vim.fn.confirm(
                    "This file is readonly on the file system. Open as root?\n",
                    "&Yes" .. "\n&No",
                    1
                ) == 1

                if not should_root then
                    return
                end

                local sudo_name = "sudo://" .. real_path
                pcall(vim.api.nvim_buf_set_name, buf, sudo_name)
                vim.bo[buf].readonly = false
                vim.bo[buf].buftype = "acwrite"
                vim.b[buf].su_real_path = real_path

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
