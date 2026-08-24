--- @class LspKeyConfig
--- @field jump_action function Callback function executed for standard language servers.
--- @field description string Documentation string for the keymap decoration.
--- @field capability? string Optional LSP method required to enable this keymap.
--- @field modes? string|string[] Optional mode override for this keymap or nil to use 'normal'

--- @param key string
--- @param lsp_config LspKeyConfig
--- @param client vim.lsp.Client
--- @param buf_id integer
local function map_if_capable(key, lsp_config, client, buf_id)
    -- Only map if no specific capability is required, or if the client supports it
    if
        not lsp_config.capability
        or client:supports_method(lsp_config.capability, buf_id)
    then
        -- Mapped directly via vim.keymap.set to bypass <leader>l
        vim.keymap.set(
            lsp_config.modes or "n",
            key,
            lsp_config.jump_action,
            { buffer = buf_id, desc = lsp_config.description }
        )
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("buffer_lsp_action", { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        -- Remaining LSP actions kept under <leader>l
        --- @type table<string, LspKeyConfig>
        local lsp_jump = {
            ["<leader>ln"] = {
                description = "Re[n]ame Symbol",
                jump_action = vim.lsp.buf.rename,
                capability = "textDocument/rename",
            },
            ["<leader>la"] = {
                description = "Code [a]ction",
                jump_action = vim.lsp.buf.code_action,
                capability = "textDocument/codeAction",
                modes = { "n", "v" },
            },
        }

        for key, config in pairs(lsp_jump) do
            local target_fn = config.jump_action

            if target_fn then
                map_if_capable(key, config, client, args.buf)
            end
        end
    end,
})
