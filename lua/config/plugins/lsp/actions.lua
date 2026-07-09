local osh_wrapper = require("omnisharp_extended")
local ts_builtin = require("telescope.builtin")
local utils = require("config.plugins.lsp.utils")

--- @class LspJumpConfig
--- @field default_lsp_action function Callback function executed for standard language servers.
--- @field lsp_action_override? table<string, function> Optional map of LSP client names to override callbacks.
--- @field description string Documentation string for the keymap decoration.

--- @type table<string, LspJumpConfig>
local lsp_jump = {
    ["n"] = {
        description = "Re[N]ame Symbol",
        default_lsp_action = vim.lsp.buf.rename,
    },
    ["a"] = {
        description = "[A]ction",
        default_lsp_action = vim.lsp.buf.code_action,
    },
    ["D"] = {
        description = "[D]eclaration",
        default_lsp_action = vim.lsp.buf.declaration,
    },
    ["sW"] = {
        description = "[S]ymbols in [W]orkspace",
        default_lsp_action = ts_builtin.lsp_document_symbols,
    },
    ["sD"] = {
        description = "[S]ymbols in [D]ocument",
        default_lsp_action = ts_builtin.lsp_dynamic_workspace_symbols,
    },
    ["t"] = {
        default_lsp_action = ts_builtin.lsp_type_definitions,
        lsp_action_override = {
            ["omnisharp"] = osh_wrapper.telescope_lsp_type_definition,
        },
        description = "[T]ype definition",
    },
    ["r"] = {
        default_lsp_action = ts_builtin.lsp_references,
        lsp_action_override = {
            ["omnisharp"] = osh_wrapper.telescope_lsp_references,
        },
        description = "[R]eferences",
    },
    ["i"] = {
        default_lsp_action = ts_builtin.lsp_implementations,
        lsp_action_override = {
            ["omnisharp"] = osh_wrapper.telescope_lsp_implementation,
        },
        description = "[I]mplementation",
    },
    ["d"] = {
        default_lsp_action = ts_builtin.lsp_definitions,
        lsp_action_override = {
            ["omnisharp"] = osh_wrapper.telescope_lsp_definitions,
        },
        description = "[D]efinition",
    },
}

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("telescope_lsp_action", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
            return
        end

        local client_name = client.name

        for key, config in pairs(lsp_jump) do
            local target_fn = config.default_lsp_action
            if config.lsp_action_override and config.lsp_action_override[client_name] then
                target_fn = config.lsp_action_override[client_name]
            end

            if target_fn then
                utils.map_lsp_key(key, target_fn, event.buf, config.description)
            end
        end
    end,
})
