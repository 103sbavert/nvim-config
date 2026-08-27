local ai = require("mini.ai")
local utils = require("config.plugins.mini_nvim.internals.ast-utils")

ai.setup({
    n_lines = 50,
    search_method = "cover_or_nearest",
    custom_textobjects = {
        -- Variable declarations / assignments (requires after/queries/<lang>/textobjects.scm)
        d = utils.make_decl_textobj(),

        -- Function implementation bodies
        f = utils.make_func_textobj(),

        -- Function calls (tweaked to not detect dot in function name)
        F = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),

        -- Blocks, loops, conditionals
        s = utils.make_scope_textobj(),
    },
})
