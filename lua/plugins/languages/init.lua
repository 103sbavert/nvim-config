local get_lang_mod = function(modname) return "plugins.languages." .. modname end

--- @type LazySpec[]
return {
    require(get_lang_mod("completion")),
    require(get_lang_mod("debug")),
    require(get_lang_mod("format")),
    require(get_lang_mod("lsp")),
    require(get_lang_mod("lint")),
    require(get_lang_mod("treesitter")),
}
