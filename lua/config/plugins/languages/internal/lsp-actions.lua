--- @class LspJumpConfig
--- @field jump_action function Callback function executed for standard language servers.
--- @field description string Documentation string for the keymap decoration.

--- @class LspSearchConfig
--- @field search_action function Callback function executed for standard language servers.
--- @field description string Documentation string for the keymap decoration.

local lsp_key_group = create_keymap_group("[l]SP", "<leader>l", { "n", "v" })

--- Maps an LSP command to a buffer-local key sequence.
--- @param keys string The key combination triggering the function.
--- @param func function The execution callback logic.
--- @param buf_id integer Target buffer sequence identifier.
--- @param desc string Description detailing map functionality.
local function map_lsp_key(keys, func, buf_id, desc)
    lsp_key_group(keys, func, desc, { buffer = buf_id })
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup(
        "telescope_lsp_action",
        { clear = true }
    ),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
            return
        end

        local ts_builtin = require("telescope.builtin")

        --- @type table<string, LspJumpConfig>
        local lsp_jump = {
            ["n"] = {
                description = "Re[n]ame Symbol",
                jump_action = vim.lsp.buf.rename,
            },
            ["a"] = {
                description = "[a]ction",
                jump_action = vim.lsp.buf.code_action,
            },
            ["D"] = {
                description = "[D]eclaration",
                jump_action = vim.lsp.buf.declaration,
            },
            ["t"] = {
                jump_action = function() ts_builtin.lsp_type_definitions() end,
                description = "[t]ype definition",
            },
            ["r"] = {
                jump_action = function() ts_builtin.lsp_references() end,
                description = "[r]eferences",
            },
            ["i"] = {
                jump_action = function() ts_builtin.lsp_implementations() end,
                description = "[i]mplementation",
            },
            ["d"] = {
                jump_action = function() ts_builtin.lsp_definitions() end,
                description = "[d]efinition",
            },
        }

        for key, config in pairs(lsp_jump) do
            local target_fn = config.jump_action

            if target_fn then
                map_lsp_key(key, target_fn, event.buf, config.description)
            end
        end

        --- @type table<string, LspSearchConfig>
        local search_keywords = {
            ["w"] = {
                description = "LSP [w]orkspace",
                search_action = function() ts_builtin.lsp_document_symbols() end,
            },
            ["s"] = {
                description = "LSP [s]ymbols",
                search_action = function()
                    ts_builtin.lsp_dynamic_workspace_symbols()
                end,
            },
        }

        for key, config in pairs(search_keywords) do
            local target_fn = config.search_action

            if target_fn then
                map_lsp_key(key, target_fn, event.buf, config.description)
            end
        end
    end,
})
