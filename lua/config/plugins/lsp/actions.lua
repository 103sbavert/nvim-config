local UT = require("config.utils")
local utils = require("config.plugins.lsp.utils")
local get_telescope_builtin = UT.lazy_require("telescope.builtin")
local get_omnisharp_ext = UT.lazy_require("omnisharp_extended")

--- @class LspJumpConfig
--- @field default_lsp_action function Callback function executed for standard language servers.
--- @field lsp_action_override? table<string, function> Optional map of LSP client names to override callbacks.
--- @field description string Documentation string for the keymap decoration.

--- @class LspSearchConfig
--- @field action function Callback function executed for standard language servers.
--- @field description string Documentation string for the keymap decoration.

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("telescope_lsp_action", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
            return
        end

        local client_name = client.name

        --- @type table<string, LspJumpConfig>
        local lsp_jump = {
            ["n"] = {
                description = "Re[n]ame Symbol",
                default_lsp_action = vim.lsp.buf.rename,
            },
            ["a"] = {
                description = "[a]ction",
                default_lsp_action = vim.lsp.buf.code_action,
            },
            ["D"] = {
                description = "[D]eclaration",
                default_lsp_action = vim.lsp.buf.declaration,
            },
            ["t"] = {
                default_lsp_action = function() get_telescope_builtin().lsp_type_definitions() end,
                lsp_action_override = {
                    ["omnisharp"] = function() get_omnisharp_ext().telescope_lsp_type_definition() end,
                },
                description = "[t]ype definition",
            },
            ["r"] = {
                default_lsp_action = function() get_telescope_builtin().lsp_references() end,
                lsp_action_override = {
                    ["omnisharp"] = function() get_omnisharp_ext().telescope_lsp_references() end,
                },
                description = "[r]eferences",
            },
            ["i"] = {
                default_lsp_action = function() get_telescope_builtin().lsp_implementations() end,
                lsp_action_override = {
                    ["omnisharp"] = function() get_omnisharp_ext().telescope_lsp_implementation() end,
                },
                description = "[i]mplementation",
            },
            ["d"] = {
                default_lsp_action = function() get_telescope_builtin().lsp_definitions() end,
                lsp_action_override = {
                    ["omnisharp"] = function() get_omnisharp_ext().telescope_lsp_definitions() end,
                },
                description = "[d]efinition",
            },
        }

        for key, config in pairs(lsp_jump) do
            local target_fn = config.default_lsp_action
            if config.lsp_action_override and config.lsp_action_override[client_name] then
                target_fn = config.lsp_action_override[client_name]
            end

            if target_fn then
                utils.map_lsp_key(key, target_fn, event.buf, config.description)
            end
        end

        --- @type table<string, LspSearchConfig>
        local search_keywords = {
            ["w"] = {
                description = "LSP [w]orkspace",
                action = function() get_telescope_builtin().lsp_document_symbols() end,
            },
            ["s"] = {
                description = "LSP [s]ymbols",
                action = function() get_telescope_builtin().lsp_dynamic_workspace_symbols() end,
            },
        }

        for key, config in pairs(search_keywords) do
            local target_fn = config.action

            if target_fn then
                utils.map_lsp_key(key, target_fn, event.buf, config.description)
            end
        end
    end,
})
