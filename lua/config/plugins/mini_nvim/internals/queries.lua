local M = {}

-- variable declarations and assignments
M.decl = {
    outer = "@assignment.outer",
    inner = "@assignment.rhs",
    langs = {
        go = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        lua = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        javascript = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        typescript = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        python = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        c = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        c_sharp = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        rust = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        bash = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
        zsh = { outer = "@vardecl.outer", inner = "@vardecl.rhs" },
    },
}

-- function definitions and implementation body
M.func_impl = {
    outer = "@function.outer",
    inner = "@function.inner",
}

-- local scopes, blocks, loops, conditionals
M.scope = {
    outer = { "@block.outer", "@loop.outer", "@conditional.outer" },
    inner = { "@block.inner", "@loop.inner", "@conditional.inner" },
}

return M
