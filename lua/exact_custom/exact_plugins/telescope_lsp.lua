local osh_wrapper = require("omnisharp_extended")
local ts_builtin = require("telescope.builtin")

--- @class LspMappingConfig
--- @field osh_fn function Callback function executed when OmniSharp is active.
--- @field ts_fn function Callback function executed for standard Language Servers.
--- @field description string Documentation string for the keymap decoration.

--- @type table<string, LspMappingConfig>
local mappings = {
    ["grt"] = {
        osh_fn = osh_wrapper.telescope_lsp_type_definition,
        ts_fn = ts_builtin.lsp_type_definitions,
        description = "[G]oto [T]ype Definition",
    },
    ["grr"] = {
        osh_fn = osh_wrapper.telescope_lsp_references,
        ts_fn = ts_builtin.lsp_references,
        description = "[G]oto [R]eferences",
    },
    ["gri"] = {
        osh_fn = osh_wrapper.telescope_lsp_implementation,
        ts_fn = ts_builtin.lsp_implementations,
        description = "[G]oto [I]mplementation",
    },
    ["grd"] = {
        osh_fn = osh_wrapper.telescope_lsp_definitions,
        ts_fn = ts_builtin.lsp_definitions,
        description = "[G]oto [D]efinition",
    },
}

--- Maps an LSP command to a buffer-local key sequence.
--- @param keys string The key combination triggering the function.
--- @param func function The execution callback logic.
--- @param buf_id integer Target buffer sequence identifier.
--- @param desc string Description detailing map functionality.
local function map_lsp_key(keys, func, buf_id, desc)
    vim.keymap.set({ "n", "v" }, keys, func, { buffer = buf_id, desc = "LSP: " .. desc })
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("omnisharp_telescope_lsp", { clear = true }),
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
            return
        end

        local omnisharp_lsp_names = {
            ["omnisharp"] = true,
            ["OmniSharp"] = true,
            ["omnisharp_roslyn"] = true,
            ["omnisharp_mono"] = true,
        }

        local is_omnisharp = omnisharp_lsp_names[client.name] or false

        for key, config in pairs(mappings) do
            local target_fn = is_omnisharp and config.osh_fn or config.ts_fn
            if target_fn then
                map_lsp_key(key, target_fn, event.buf, config.description)
            end
        end
    end,
})
