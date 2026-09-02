local M = {}

--- Files the user opted out of applying, for this session.
--- @type table<string, boolean>
local muted = {}

--- Files auto-applied on every write, for this session.
--- @type table<string, boolean>
local watched = {}

--- Buffers already wired for cleanup.
--- @type table<integer, boolean>
local tracked = {}

local group = vim.api.nvim_create_augroup("ChezmoiState", { clear = true })

--- @param file string
--- @return boolean
function M.is_muted(file) return muted[file] == true end

--- @param file string
function M.mute(file) muted[file] = true end

--- @param file string
--- @return boolean
function M.is_watched(file) return watched[file] == true end

--- @param file string
function M.watch(file) watched[file] = true end

--- Drops all session flags for a file.
--- @param file string
local function clear(file)
    muted[file] = nil
    watched[file] = nil
end

--- Clears a file's flags once its buffer is deleted or renamed.
--- @param buf integer? Buffer id.
--- @param file string? File the flags are keyed by.
function M.track_buf(buf, file)
    if not buf or not file or tracked[buf] then
        return
    end

    tracked[buf] = true

    vim.api.nvim_create_autocmd({ "BufDelete", "BufFilePre" }, {
        -- `buffer`, not `buf`: the latter is silently ignored, which makes the
        -- autocmd global and clears state on unrelated buffer deletes.
        buffer = buf,
        once = true,
        group = group,
        callback = function()
            tracked[buf] = nil
            clear(file)
        end,
    })
end

return M
