local M = {}

local lsp_key_group = create_keymap_group("[l]SP", "<leader>l", { "n", "v" })

--- Maps an LSP command to a buffer-local key sequence.
--- @param keys string The key combination triggering the function.
--- @param func function The execution callback logic.
--- @param buf_id integer Target buffer sequence identifier.
--- @param desc string Description detailing map functionality.
function M.map_lsp_key(keys, func, buf_id, desc) lsp_key_group(keys, func, desc, { buffer = buf_id }) end

return M
