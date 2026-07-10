local wk = require("which-key")

wk.setup({
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    preset = "helix",
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
        { "gc", group = "Comments", { "n", "v" } },
    },
})

local registered_groups = {}

--- Generates a keymapping factory function and registers the group description with which-key.nvim.
--- @param group_name string The description prefix and group name (e.g., "LSP").
--- @param key_prefix string The prefix prepended to all generated key combinations (e.g., "<leader>l").
--- @param default_modes string|table The fallback modes if none are provided during mapping.
--- @return fun(keys: string, func: string|function, desc: string, opts?: vim.keymap.set.Opts, modes?: string|table) mapping_fn
function _G.create_keymap_group(group_name, key_prefix, default_modes)
    -- Only register with which-key if the group_name has not been processed yet
    if not registered_groups[group_name] then
        wk.add({
            { key_prefix, group = group_name, mode = default_modes },
        })
        registered_groups[group_name] = true
    end

    return function(keys, func, desc, opts, modes)
        local final_opts = vim.tbl_deep_extend("force", {}, opts or {})

        final_opts.desc = desc

        local target_modes = modes or default_modes
        local full_keys = key_prefix .. keys

        vim.keymap.set(target_modes, full_keys, func, final_opts)
    end
end

local toggle_key_group = create_keymap_group("[t]oggle", "<leader>t", { "n" })

--- Maps toggle keys, and optionally notifies
--- @param keys string The key combination triggering the function.
--- @param func fun(): string?, boolean The callback logic. Returns the message string, and a bool indicating if it should be shown.
--- @param desc string Description detailing map functionality.
function _G.map_toggle_key(keys, func, desc)
    local function toggle_fn()
        local message, should_notify = func()

        if should_notify and message and message ~= "" then
            vim.notify(message, vim.log.levels.INFO)
        end
    end

    toggle_key_group(keys, toggle_fn, desc)

    vim.keymap.set({ "n" }, "<leader>t" .. keys, toggle_fn, { desc = desc })
end
