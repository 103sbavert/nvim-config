--- @type LazySpec
return {
    main = "which-key",
    "folke/which-key.nvim",
    --- @type wk.Opts
    opts = {
        delay = 250,
        preset = "helix",
        icons = { mappings = vim.g.have_nerd_font },
        spec = {
            { "gw", desc = "Text formatting", mode = { "n", "v" } },
            { "gq", desc = "LSP formatting", mode = { "n", "v" } },
            { "ga", group = "[g]oto c[a]lls", mode = { "n", "v" } },
            { "gc", group = "Comments", mode = { "n", "v" } },
            { "<leader>s", group = "[s]earch", mode = { "n", "v" } },
            { "<leader>l", group = "[l]SP", mode = { "n", "v" } },
            { "<leader>z", group = "Che[z]moi", mode = { "n" } },
        },
    },
    config = function(plugin, opts)
        --- @module "which-key"
        local wk = require(plugin.main)
        wk.setup(opts)

        local registered_groups = {}

        --- @param group_name string Label for the key group, shown in which-key pop-up
        --- @param prefix_keys string Group prefix key sequence (such as "<leadder>F" for all key maps starting in "<leader>F")
        --- @param default_modes string|string[] Default vim modes
        --- @return fun(keys: string, func: string|function, desc: string, opts: vim.keymap.set.Opts?, modes?: string|string[]): nil
        function _G.create_keymap_group(group_name, prefix_keys, default_modes)
            if not registered_groups[group_name] then
                wk.add({
                    { prefix_keys, group = group_name, mode = default_modes },
                })
                registered_groups[group_name] = true
            end

            return function(keys, func, desc, keymap_opts, modes)
                local final_opts =
                    vim.tbl_deep_extend("force", {}, keymap_opts or {})
                final_opts.desc = desc
                local target_modes = modes or default_modes
                local full_keys = prefix_keys .. keys
                vim.keymap.set(target_modes, full_keys, func, final_opts)
            end
        end

        local toggle_key_group =
            create_keymap_group("[t]oggle", "<leader>t", { "n" })

        --- @param keys string Key suffix
        --- @param func fun(): (string|nil, boolean|nil) Function returning message and notify flag
        --- @param desc string Keymap description
        function _G.map_toggle_key(keys, func, desc)
            local function toggle_fn()
                local message, should_notify = func()
                if should_notify and message and message ~= "" then
                    vim.notify(message, vim.log.levels.INFO)
                end
            end

            toggle_key_group(keys, toggle_fn, desc)
            vim.keymap.set(
                { "n" },
                "<leader>t" .. keys,
                toggle_fn,
                { desc = desc }
            )
        end
    end,
}
