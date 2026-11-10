-- Section targets: top-level nodes
-- Comments are excluded and top-level `do...end` lines are transparent (their
-- direct children are targets, not them)

local motion = require("config.section_motion")

--- @return Section[]
local function collect()
    local ok, parser = pcall(vim.treesitter.get_parser, 0, "lua")
    if not ok or not parser then
        return {}
    end

    local sections = {}
    local function add(node)
        if node:named() and node:type() ~= "comment" then
            sections[#sections + 1] = motion.span(node)
        end
    end

    for child in parser:parse()[1]:root():iter_children() do
        local body = child:type() == "do_statement" and child:field("body")[1]
        if body then
            for stmt in body:iter_children() do
                add(stmt)
            end
        else
            add(child)
        end
    end

    return sections
end

motion.setup(collect, "did_lua_ftplugin")
