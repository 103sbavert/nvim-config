local ai = require("mini.ai")
local lazy_utils = function()
    return require("config.plugins.mini_nvim.internals.ast-utils")
end

ai.setup({
    n_lines = 50,
    search_method = "cover_or_nearest",
    custom_textobjects = {
        -- Variable declarations / assignments (requires after/queries/<lang>/textobjects.scm)
        d = lazy_utils().make_decl_textobj(),

        -- Function implementation bodies
        f = lazy_utils().make_func_textobj(),

        -- Function calls (tweaked to not detect dot in function name)
        F = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),

        -- Blocks, loops, conditionals
        s = lazy_utils().make_scope_textobj(),
    },
})
