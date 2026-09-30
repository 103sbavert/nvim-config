---@class snacks.picker.git.Item: snacks.picker.Item
---@field commit string the base commit hash for diff
---@field target_ref? string optional target ref - "HEAD" if not specified

--- @param modname string name of the module to load
--- @return table
local set_get_mod = function(modname)
    local ok, mod = pcall(require, modname)

    assert(ok, "Unable to load Codediff. Is the plugin installed and loaded?")

    return mod
end

--- @return snacks.picker.layout.Config
local function create_diff_layout()
    local layout = vim.deepcopy(require("snacks.picker.config.layouts").default)

    layout.fullscreen = true
    layout.layout.border = true

    for _, prop in ipairs(layout.layout) do
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

    return layout
end

require("snacks.picker.config.layouts").git_diff = create_diff_layout()

--- @type fun(self: snacks.Picker, item?: snacks.picker.git.Item)
local function show_diff(self, item)
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

    set_get_mod("codediff.commands.handlers.git_diff").run(
        item.commit,
        item.target_ref,
        {}
    )
end

require("snacks.picker.actions").git_show_diff = show_diff
