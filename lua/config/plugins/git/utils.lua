local M = {}

-- Initialize mappers
--- Keymap group for git actions, mapped under "<leader>g".
M.git_key_mapper = create_keymap_group("[g]it", "<leader>g", { "n", "v" })
--- Keymap group for backward hunk/change navigation, mapped under "[".
M.navigate_bw_mapper = create_keymap_group("[ backwards", "[", { "n", "v" })
--- Keymap group for forward hunk/change navigation, mapped under "]".
M.navigate_fw_mapper = create_keymap_group("] forwards", "]", { "n", "v" })

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
--- @param head_sha string Full/short SHA of the current HEAD commit.
--- @param item snacks.picker.Item Git log picker item being formatted.
--- @param picker snacks.Picker Picker instance the item belongs to.
--- @return snacks.picker.Highlight[] Formatted item parts with head highlighting.
local function git_log_formatter(head_sha, item, picker)
    local formatted_item = Snacks.picker.format.git_log(item, picker)

    local is_head = item.commit and vim.startswith(head_sha, item.commit)
    local symbol = is_head and "@" or ""
    local hl = is_head and "SnacksPickerSpecial" or nil

    local snacks_align = Snacks.picker.util.align
    table.insert(formatted_item, 3, { snacks_align(symbol, 4), hl })

    return formatted_item
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

--- Opens a picker over the current file's git log so the user can choose a
--- base commit to diff against. Notifies and aborts if there is no active
--- buffer file or the file is untracked.
--- @param callback fun(hash: string) Invoked with the chosen commit hash.
--- @return nil
function M.open_commit_picker(callback)
    local file_name = require("config.utils").get_current_file()

    if not file_name then
        vim.notify(
            "No active file in current buffer",
            vim.log.levels.WARN,
            { title = "Diff" }
        )
        return
    end

    local utils = require("config.utils")
    utils.is_file_tracked(file_name, function(is_tracked)
        if not is_tracked then
            vim.notify(
                "File is new/untracked",
                vim.log.levels.WARN,
                { title = "Diff" }
            )
            return
        end

        utils.git_run({ "git", "rev-parse", "HEAD" }, function(head_res)
            local head_hash = vim.trim(head_res.stdout or "")

            --- @type snacks.picker.git.log.Config
            local git_log_opts = {
                format = function(item, picker)
                    return git_log_formatter(head_hash, item, picker)
                end,
                current_file = true,
                title = "Pick diff base",
                confirm = function(picker, item)
                    on_ref_confirm(picker, item, callback)
                end,
            }

            Snacks.picker.git_log(git_log_opts)
        end, { error_title = "Diff", notify_on_error = true })
    end)
end

return M
