---@class snacks.picker.git.Item: snacks.picker.Item
---@field commit string the base commit hash for diff
---@field target_ref? string optional target ref - "HEAD" if not specified

--- @type snacks.picker.layout.Config
local log_layout = {
    fullscreen = true,
    layout = {
        box = "horizontal",
        width = 0.8,
        min_width = 120,
        height = 0.8,
        border = true,
        {
            box = "vertical",
            border = false,
            title = "{title} {live} {flags}",
            { win = "input", height = 1, border = "bottom" },
            { win = "list", border = false },
        },
        { win = "preview", title = "{preview}", border = "left", width = 0.7 },
    },
}

--- @type fun(self: snacks.Picker, item?: snacks.picker.git.Item)
local function show_diff_action(self, item)
    if not self.closed then
        self:close()
    end

    if not item or not item.commit then
        vim.notify(
            "No item selected",
            vim.log.levels.WARN,
            { title = "Snacks picker" }
        )
        return
    end

    vim.cmd({
        cmd = "CodeDiff",
        args = { item.commit, item.target_ref },
    })
end

return {
    git_log_layout = log_layout,
    git_show_diff = show_diff_action,
}
