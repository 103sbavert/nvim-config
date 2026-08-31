local UT = require("config.utils")

---@type fun(): ChezmoiExecuteTemplate
local get_cmd_execute_template =
    UT.lazy_require("nvim-chezmoi.chezmoi.commands.execute_template")

local utils = require("config.plugins.chezmoi.utils")

local is_preview_mode = false
--- @type integer?
local preview_buf = nil
--- @type integer?
local preview_win = nil
local syncing = false

local template_grp =
    vim.api.nvim_create_augroup("czm_template", { clear = true })

--- Returns the proportionally equivalent line in the target buffer given a source position.
--- @param line integer 1-based current line in the source buffer
--- @param src_count integer Total lines in the source buffer
--- @param tgt_count integer Total lines in the target buffer
--- @return integer 1-based target line (clamped to [1, tgt_count])
local function proportional_line(line, src_count, tgt_count)
    if src_count == 0 or tgt_count == 0 then
        return 1
    end
    return math.max(
        1,
        math.min(
            tgt_count,
            math.floor((line - 1) / src_count * tgt_count + 0.5) + 1
        )
    )
end

--- Clears render augroup, closes preview window, resets all state.
local function disable_preview_mode()
    is_preview_mode = false

    vim.api.nvim_clear_autocmds({ group = "czm_template_render" })

    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        vim.api.nvim_clear_autocmds({
            group = template_grp,
            buffer = preview_buf,
        })
    end

    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
        pcall(vim.api.nvim_win_close, preview_win, true)
    end

    preview_buf = nil
    preview_win = nil
end

--- Executes the template and writes result into the single preview buffer.
--- @param buf_file string Absolute path of the source .tmpl file being rendered.
local function render_template(buf_file)
    if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
        return
    end

    local src_bufnr = vim.fn.bufnr(buf_file)
    if src_bufnr == -1 then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false)
    local content = table.concat(lines, "\n")

    get_cmd_execute_template():async({ content }, function(result)
        local buf_still_valid = preview_buf ~= nil
            and vim.api.nvim_buf_is_valid(preview_buf)

        if not result.success or not buf_still_valid then
            return
        end

        local ft = vim.bo[src_bufnr].filetype

        if ft and ft ~= "" then
            vim.bo[preview_buf].filetype = ft
        end

        vim.bo[preview_buf].modifiable = true
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, result.data)
        vim.bo[preview_buf].modifiable = false

        -- Sync cursor from source window into preview window after render.
        if preview_win and vim.api.nvim_win_is_valid(preview_win) then
            local src_win = vim.fn.bufwinid(src_bufnr)
            if src_win ~= -1 then
                local src_line = vim.api.nvim_win_get_cursor(src_win)[1]
                local src_count = vim.api.nvim_buf_line_count(src_bufnr)
                local preview_count = vim.api.nvim_buf_line_count(preview_buf)
                pcall(
                    vim.api.nvim_win_set_cursor,
                    preview_win,
                    { proportional_line(src_line, src_count, preview_count), 0 }
                )
            end
            vim.wo[preview_win].winbar = vim.fs.basename(buf_file)
                .. " template preview"
        end
    end)
end

--- Creates the render augroup and registers BufReadPost+BufWritePost on the src_dir pattern.
--- @param pattern string|string[] Glob pattern scoped to the chezmoi source directory.
local function enable_render_autocmds(pattern)
    local render_grp =
        vim.api.nvim_create_augroup("czm_template_render", { clear = true })

    vim.api.nvim_create_autocmd(
        { "BufWinEnter", "CursorHold", "CursorHoldI" },
        {
            group = render_grp,
            pattern = pattern,
            callback = function(args)
                if not is_preview_mode then
                    return
                end

                render_template(vim.api.nvim_buf_get_name(args.buf))
            end,
        }
    )
end

--- Registers bidirectional cursor sync between the source buffer and preview window.
--- Uses the czm_template_render group so it's cleaned up automatically on disable.
--- @param source_buf integer Buffer number of the template source file.
local function enable_cursor_sync(source_buf)
    local render_grp =
        vim.api.nvim_create_augroup("czm_template_render", { clear = false })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = render_grp,
        buffer = source_buf,
        callback = function()
            if
                syncing
                or not preview_win
                or not vim.api.nvim_win_is_valid(preview_win)
            then
                return
            end
            syncing = true
            local src_win = vim.fn.bufwinid(source_buf)
            if src_win ~= -1 then
                local line = vim.api.nvim_win_get_cursor(src_win)[1]
                local src_count = vim.api.nvim_buf_line_count(source_buf)
                local preview_count =
                    vim.api.nvim_buf_line_count(preview_buf or 0)
                pcall(
                    vim.api.nvim_win_set_cursor,
                    preview_win,
                    { proportional_line(line, src_count, preview_count), 0 }
                )
            end
            syncing = false
        end,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = render_grp,
        buffer = preview_buf,
        callback = function()
            if
                syncing
                or not preview_win
                or not vim.api.nvim_win_is_valid(preview_win)
            then
                return
            end
            syncing = true
            local line = vim.api.nvim_win_get_cursor(preview_win)[1]
            local preview_count = vim.api.nvim_buf_line_count(preview_buf or 0)
            local src_win = vim.fn.bufwinid(source_buf)
            if src_win ~= -1 then
                local src_count = vim.api.nvim_buf_line_count(source_buf)
                pcall(
                    vim.api.nvim_win_set_cursor,
                    src_win,
                    { proportional_line(line, preview_count, src_count), 0 }
                )
            end
            syncing = false
        end,
    })
end

--- Enables preview mode: creates the shared buffer/window, registers render autocmds,
--- then immediately renders the given template file.
--- @param buf_file string Absolute path of the template file to render first.
--- @param pattern string|string[] Autocmd pattern for all template files in the source dir.
local function enable_preview_mode(buf_file, pattern)
    is_preview_mode = true

    -- Create single shared preview buffer
    if not preview_buf or not vim.api.nvim_buf_is_valid(preview_buf) then
        preview_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[preview_buf].bufhidden = "wipe"
        vim.bo[preview_buf].modifiable = false

        -- Auto-disable when user closes the preview buffer by any means
        vim.api.nvim_create_autocmd("BufWipeout", {
            group = template_grp,
            buffer = preview_buf,
            once = true,
            callback = disable_preview_mode,
        })
    else
    end

    -- Open horizontal split below; restore focus immediately
    if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
        local current_win = vim.api.nvim_get_current_win()
        vim.cmd("split")
        preview_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(preview_win, preview_buf)
        vim.api.nvim_set_current_win(current_win)
    else
    end

    local source_bufnr = vim.fn.bufnr(buf_file)
    enable_render_autocmds(pattern)
    if source_bufnr ~= -1 then
        enable_cursor_sync(source_bufnr)
    end
    render_template(buf_file)
end

-- Register all autocmds once src_dir is known.
utils.get_src_dir_async(function(src_dir)
    if not src_dir then
        return
    end

    local tmpl_pattern = {
        vim.fs.joinpath(src_dir, "*.tmpl"),
        vim.fs.joinpath(src_dir, "**", "*.tmpl"),
    }

    -- Register buffer-local <leader>zt keymap on every template file opened.
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        group = template_grp,
        pattern = tmpl_pattern,
        callback = function(args)
            local buf_id = args.buf

            local buf_file = UT.get_current_file(args)

            if not buf_file then
                return
            end

            vim.keymap.set("n", "<leader>zt", function()
                if is_preview_mode then
                    disable_preview_mode()
                else
                    enable_preview_mode(buf_file, tmpl_pattern)
                end
            end, {
                buffer = buf_id,
                desc = "Toggle [t]emplate preview",
            })
        end,
    })
end)
