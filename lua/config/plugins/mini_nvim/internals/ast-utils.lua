local M = {}

local opts = {
    use_nvim_treesitter = true,
}

-- Variable declarations / assignments
M.make_decl_textobj = function()
    return require("mini.ai").gen_spec.treesitter({
        a = "@assignment.outer",
        i = "@assignment.rhs",
    }, opts)
end

-- Function definitions
M.make_func_textobj = function()
    return require("mini.ai").gen_spec.treesitter({
        a = "@function.outer",
        i = "@function.inner",
    }, opts)
end

-- Blocks, loops, conditionals
M.make_scope_textobj = function()
    return require("mini.ai").gen_spec.treesitter({
        a = { "@block.outer", "@loop.outer", "@conditional.outer" },
        i = { "@block.inner", "@loop.inner", "@conditional.inner" },
    }, opts)
end

return M
