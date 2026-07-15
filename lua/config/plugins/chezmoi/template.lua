local cmd_execute_template = require("nvim-chezmoi.chezmoi.commands.execute_template")
local utils = require("config.plugins.chezmoi.utils")

local is_preview_mode = false
--- @type integer?
local preview_buf = nil
--- @type integer?
local preview_win = nil

local template_grp = vim.api.nvim_create_augroup("czm_template", { clear = true })

--- Clears render augroup, closes preview window, resets all state.
local function disable_preview_mode()
    is_preview_mode = false

    vim.api.nvim_clear_autocmds({ group = "czm_template_render" })

    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        vim.api.nvim_clear_autocmds({ group = template_grp, buffer = preview_buf })
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

    cmd_execute_template:async({ content }, function(result)
        local buf_still_valid = preview_buf ~= nil and vim.api.nvim_buf_is_valid(preview_buf)

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
        if preview_win and vim.api.nvim_win_is_valid(preview_win) then
            vim.wo[preview_win].winbar = vim.fs.basename(buf_file) .. " template preview"
        end
    end)
end

--- Creates the render augroup and registers BufReadPost+BufWritePost on the src_dir pattern.
--- @param pattern string|string[] Glob pattern scoped to the chezmoi source directory.
local function enable_render_autocmds(pattern)
    local render_grp = vim.api.nvim_create_augroup("czm_template_render", { clear = true })

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufWinEnter", "BufEnter", "BufReadPost" }, {
        group = render_grp,
        pattern = pattern,
        callback = function(args)
            if not is_preview_mode then
                return
            end

            render_template(vim.api.nvim_buf_get_name(args.buf))
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

    enable_render_autocmds(pattern)
    render_template(buf_file)
end

-- Register all autocmds once src_dir is known.
utils.get_src_dir(function(src_dir)
    if not src_dir then
        return
    end

    local src_dir_pattern = { src_dir .. "/*.tmpl", src_dir .. "/**/*.tmpl" }

    -- Register buffer-local <leader>zt keymap on every template file opened.
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        group = template_grp,
        pattern = src_dir_pattern,
        callback = function(args)
            local buf_id = args.buf
            if not vim.api.nvim_buf_is_valid(buf_id) then
                return
            end

            local buf_type = vim.bo[buf_id].filetype
            if not buf_type or buf_type == "" then
                return
            end

            local buf_file = vim.api.nvim_buf_get_name(buf_id)
            if buf_file == "" then
                return
            end

            vim.keymap.set("n", "<leader>zt", function()
                if is_preview_mode then
                    disable_preview_mode()
                else
                    enable_preview_mode(buf_file, src_dir_pattern)
                end
            end, { buffer = buf_id, desc = "Toggle [t]emplate preview" })
        end,
    })
end)
