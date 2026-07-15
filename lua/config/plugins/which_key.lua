return {
    "folke/which-key.nvim",
    config = function()
        local wk = require("which-key")

        wk.setup({
            delay = 0,
            preset = "helix",
            icons = { mappings = vim.g.have_nerd_font },
            spec = {
                { "gc", group = "Comments", mode = { "n", "v" } },
            },
        })

        local registered_groups = {}

        ---@param group_name string Label for the key group
        ---@param key_prefix string Leader key sequence
        ---@param default_modes string|string[] Default vim modes
        ---@return fun(keys: string, func: string|function, desc: string, opts: table?, modes: string|string[]?): nil
        function _G.create_keymap_group(group_name, key_prefix, default_modes)
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

        ---@param keys string Key suffix
        ---@param func fun(): (string|nil, boolean|nil) Function returning message and notify flag
        ---@param desc string Keymap description
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
    end,
}
