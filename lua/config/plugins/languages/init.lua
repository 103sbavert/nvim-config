local get_lang_mod = function(modname) return "config.plugins.languages." .. modname end

---@type LazySpec[]
return {
    require(get_lang_mod("completions")),
    require(get_lang_mod("debuggers")),
    require(get_lang_mod("diagnostics")),
    require(get_lang_mod("formatting")),
    require(get_lang_mod("language-servers")),
    require(get_lang_mod("linters")),
    require(get_lang_mod("treesitters")),
}
