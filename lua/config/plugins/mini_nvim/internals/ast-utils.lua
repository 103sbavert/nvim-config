local ai = require("mini.ai")
local queries = require("config.plugins.mini_nvim.internals.queries")

local M = {}

--- Build a textobject function from a query config entry (see queries.lua).
--- Resolves per-language captures from config.langs[lang], falling back to
--- config.outer / config.inner for unlisted languages.
--- The resolved gen_spec is memoised per language after first use.
local function make_spec(config)
    local get_lang = vim.treesitter.language.get_lang

    return function(ai_type, id, opts)
        local ft = vim.bo.filetype
        local lang = (get_lang and get_lang(ft)) or ft
        local ov = config.langs[lang]
        return ai.gen_spec.treesitter({
            a = (ov and ov.outer) or config.outer,
            i = (ov and ov.inner) or config.inner,
        })(ai_type, id, opts)
    end
end

--- Variable declarations / assignments
M.make_decl_textobj = function() return make_spec(queries.decl) end

--- Function definitions
M.make_func_textobj = function()
    return ai.gen_spec.treesitter({
        a = queries.func_impl.outer,
        i = queries.func_impl.inner,
    })
end

--- Blocks, loops, conditionals
M.make_scope_textobj = function()
    return ai.gen_spec.treesitter({
        a = queries.scope.outer,
        i = queries.scope.inner,
    })
end

return M
