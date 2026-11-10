-- Section targets: top-level declarations.
-- The package clause, imports and comments are excluded.

local motion = require("config.section_motion")

local targets = {
    function_declaration = true,
    method_declaration = true,
    type_declaration = true,
    const_declaration = true,
    var_declaration = true,
}

--- @return Section[]
local function collect()
    local ok, parser = pcall(vim.treesitter.get_parser, 0, "go")
    if not ok or not parser then
        return {}
    end

    local sections = {}
    for child in parser:parse()[1]:root():iter_children() do
        if targets[child:type()] then
            sections[#sections + 1] = motion.span(child)
        end
    end

    return sections
end

motion.setup(collect, "did_go_ftplugin")
