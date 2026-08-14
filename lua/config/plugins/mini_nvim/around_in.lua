local ai = require("mini.ai")
local utils = require("config.plugins.mini_nvim.internals.ast-utils")

ai.setup({
    n_lines = 500,
    search_method = "cover_or_nearest",
    custom_textobjects = {
        -- Variable declarations / assignments (requires after/queries/<lang>/textobjects.scm)
        d = utils.make_decl_textobj(),

        -- Function definitions
        F = utils.make_func_textobj(),

        -- Blocks, loops, conditionals
        s = utils.make_scope_textobj(),
    },
})
