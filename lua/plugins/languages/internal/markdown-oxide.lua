local M = {}
local default_capabilities = vim.lsp.protocol.make_client_capabilities()

M.lsp_config = {
    capabilities = vim.tbl_deep_extend("force", default_capabilities, {
        workspace = {
            didChangeWatchedFiles = {
                dynamicRegistration = true,
            },
        },
    }),
}

return M
