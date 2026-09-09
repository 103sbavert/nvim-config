local M = {}

-- Initialize mappers
--- Keymap group for git actions, mapped under "<leader>g".
M.git_key_mapper = create_keymap_group("<leader>g", { "n", "v" })
--- Keymap group for backward hunk/change navigation, mapped under "[".
M.navigate_bw_mapper = create_keymap_group("[", { "n", "v" })
--- Keymap group for forward hunk/change navigation, mapped under "]".
M.navigate_fw_mapper = create_keymap_group("]", { "n", "v" })

-- Cached Neogit commit popup instance, built lazily on first use.
local commit_popup = nil

--- Builds (once) and shows the Neogit commit popup, then triggers its commit
--- action. Assumes `neogit.lib.git` hooks are already refreshed.
--- @return nil
local function commit_popup_cb()
    commit_popup = commit_popup
        or require("neogit.lib.popup")
            .builder()
            :name("NeogitCommitPopup")
            :build()
    require("neogit.popups.commit.actions").commit(commit_popup)
end

--- Opens the Neogit commit popup, refreshing repo hooks first if needed.
--- @return nil
function M.open_commit_tab()
    local git = require("neogit.lib.git")
    if git.repo.state.hooks == nil then
        git.repo:dispatch_refresh({
            source = "commit-keymap",
            callback = function()
                require("neogit.lib.async").void(commit_popup_cb)()
            end,
        })
    else
        require("neogit.lib.async").void(commit_popup_cb)()
    end
end

--- Formats a git log picker item, prefixing it with a "@" marker column when
--- the item's commit is the current HEAD.
--- @param head_hash string Full SHA of the current HEAD commit.
--- @param item snacks.picker.Item Git log picker item being formatted.
--- @param picker snacks.Picker Picker instance the item belongs to.
--- @return snacks.picker.Highlight[] Formatted item parts with head highlighting.
local function format_log(head_hash, item, picker)
    local align = Snacks.picker.util.align

    local is_head = vim.startswith(head_hash, item.commit)
    local symbol
    local hl

    if is_head then
        symbol = " "
        hl = "SnacksPickerGitBranchCurrent"
    else
        symbol = picker.opts.icons.git.commit
        hl = "SnacksPickerGitCommit"
    end

    local shorthash = align(item.commit, 7, { truncate = true })

    local fmt = {} ---@type snacks.picker.Highlight[]
    fmt[#fmt + 1] = { symbol, hl }
    fmt[#fmt + 1] = { shorthash, hl }

    fmt[#fmt + 1] = { align("", 4) }

    Snacks.picker.highlight.extend(
        fmt,
        Snacks.picker.format.commit_message(item, picker)
    )

    return fmt
end

--- Confirm handler for the diff-base commit picker. Closes the picker and
--- forwards the selected commit hash to `callback`; notifies and aborts if
--- no commit was selected.
--- @param picker snacks.Picker Picker instance to close.
--- @param item snacks.picker.Item? Selected picker item.
--- @param callback fun(hash: string) Invoked with the selected commit hash.
--- @return nil
local function on_ref_confirm(picker, item, callback)
    picker:close()

    local hash = item and item.commit or nil
    if not hash or hash == "" then
        vim.notify(
            "No commit selected",
            vim.log.levels.WARN,
            { title = "Diff" }
        )
        return
    end

    callback(hash)
end

--- Cached layout config for Snacks.picker.git_log using default options but
--- with a wider preview and fullscreen window
--- @type snacks.picker.layout.Config
local log_layout = nil

--- @return snacks.picker.layout.Config
local function get_log_layout()
    if log_layout then
        return log_layout
    end

    log_layout = vim.deepcopy(require("snacks.picker.config.layouts").default)

    log_layout.fullscreen = true
    log_layout.layout.border = true

    for _, prop in ipairs(log_layout.layout) do
        if prop and type(prop) == "table" then
            if prop.box == "vertical" then
                prop.border = false

                for _, child in ipairs(prop) do
                    if child and type(child) == "table" then
                        if child.win == "input" then
                            child.border = "bottom"
                        elseif child.win == "list" then
                            child.border = false
                        end
                    end
                end
            elseif prop.win == "preview" then
                prop.width = 0.70
                prop.border = "left"
            end
        end
    end

    return log_layout
end

--- Opens a picker over the current file's git log so the user can choose a
--- base commit to diff against. Notifies and aborts if there is no active
--- buffer file or the file is untracked.
--- @param file_name? string optional file name to query log against
--- @param callback? fun(hash: string) Invoked with the chosen commit hash, use
--- nil to use Snacks.picker.git_log default on_confirm action
--- @return nil
function M.git_log_picker(file_name, callback)
    local utils = require("config.utils")
    utils.git_run({ "git", "rev-parse", "HEAD" }, function(head_res)
        local head_hash = vim.trim(head_res.stdout or "")

        --- @type snacks.picker.git.log.Config
        local git_log_opts = {
            format = function(item, picker)
                return format_log(head_hash, item, picker)
            end,
            cmd_args = { file_name },
            title = "Pick diff base",
            layout = get_log_layout(),
            confirm = callback and function(picker, item)
                on_ref_confirm(picker, item, callback)
            end or nil,
        }

        Snacks.picker.git_log(git_log_opts)
    end, { error_title = "Diff", notify_on_error = true })
end

return M
