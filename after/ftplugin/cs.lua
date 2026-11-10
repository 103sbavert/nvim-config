-- Section targets: top-level type declarations and their members, plus
-- top-level statements.
-- Usings, the file-scoped namespace, comments and preprocessor regions are
-- excluded.
local motion = require("config.section_motion")

local type_decls = {
    class_declaration = true,
    interface_declaration = true,
    record_declaration = true,
    struct_declaration = true,
    enum_declaration = true,
    delegate_declaration = true,
}

local member_lists = {
    declaration_list = true,
    enum_member_declaration_list = true,
}

local member_skip = {
    comment = true,
    attribute_list = true,
    preproc_region = true,
    preproc_endregion = true,
}

--- @return Section[]
local function collect()
    local ok, parser = pcall(vim.treesitter.get_parser, 0, "c_sharp")
    if not ok or not parser then
        return {}
    end

    local sections = {}
    for node in parser:parse()[1]:root():iter_children() do
        if type_decls[node:type()] then
            sections[#sections + 1] = motion.header(node)
            for child in node:iter_children() do
                if member_lists[child:type()] then
                    for member in child:iter_children() do
                        if
                            member:named() and not member_skip[member:type()]
                        then
                            sections[#sections + 1] = motion.span(member)
                        end
                    end
                end
            end
        elseif node:type() == "global_statement" then
            sections[#sections + 1] = motion.span(node)
        end
    end

    return sections
end

motion.setup(collect, "did_cs_ftplugin")
