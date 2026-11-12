local M = {}

--- @param _ lsp.InitializeParams
--- @param config vim.lsp.ClientConfig
local function before_init(_, config)
    local font_paths = require("config.utils").get_env_paths(
        { config.root_dir, vim.fn.getcwd() },
        ".typstrc",
        "TYPST_FONT_PATHS"
    )

    if font_paths then
        config.settings = config.settings or {}
        config.settings.fontPaths = font_paths
    end
end

--- @type vim.lsp.Config
M.lsp_config = {
    settings = {
        formatterMode = "typstyle",
        semanticTokens = "enabled",
    },
    before_init = before_init,
}

return M
