local M = {}

local treesitter_spec = require("mini.ai").gen_spec.treesitter

local opts = {
    use_nvim_treesitter = true,
}

--- Variable declarations / assignments
M.make_decl_textobj = function()
    return treesitter_spec({
        a = "@assignment.outer",
        i = "@assignment.rhs",
    }, opts)
end

--- Function definitions
M.make_func_textobj = function()
    return treesitter_spec({
        a = "@function.outer",
        i = "@function.inner",
    }, opts)
end

--- Blocks, loops, conditionals
M.make_scope_textobj = function()
    return treesitter_spec({
        a = { "@block.outer", "@loop.outer", "@conditional.outer" },
        i = { "@block.inner", "@loop.inner", "@conditional.inner" },
    }, opts)
end

return M
