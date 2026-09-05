--- @type LazyKeysSpec[]
return {
    -- File explorer
    {
        "\\",
        function()
            local explorer = Snacks.picker.get({ source = "explorer" })[1]

            if not explorer then
                Snacks.explorer()
            elseif explorer:is_focused() then
                vim.cmd.wincmd("p")
            else
                explorer:focus()
            end
        end,
        desc = "[\\] Toggle Explorer Focus",
    },
    -- File search (top-level shortcuts)
    {
        "<leader>\\",
        function() Snacks.picker.files() end,
        desc = "[\\] Workspace Files",
    },
    {
        "<leader><leader>",
        function() Snacks.picker.buffers() end,
        desc = "[ ] Recent Files",
    },
    {
        "<leader>?",
        function() Snacks.picker.grep() end,
        desc = "[?] Grep Workspace",
    },
    {
        "<leader>/",
        function() Snacks.picker.lines() end,
        desc = "[/] Grep Buffer",
    },
    -- LSP jump bindings
    {
        "gs",
        function() Snacks.picker.lsp_symbols() end,
        desc = "[g]oto [s]ymbols",
    },
    {
        "gd",
        function() Snacks.picker.lsp_definitions() end,
        desc = "[g]oto [d]efinition",
    },
    {
        "gD",
        function() Snacks.picker.lsp_declarations() end,
        desc = "[g]oto [D]eclaration",
    },
    {
        "gr",
        function() Snacks.picker.lsp_references() end,
        nowait = true,
        desc = "[g]oto [r]eferences",
    },
    {
        "gI",
        function() Snacks.picker.lsp_implementations() end,
        desc = "[g]oto [I]mplementation",
    },
    {
        "gy",
        function() Snacks.picker.lsp_type_definitions() end,
        desc = "[g]oto t[y]pe Definition",
    },
    {
        "gai",
        function() Snacks.picker.lsp_incoming_calls() end,
        desc = "[i]ncoming",
    },
    {
        "gao",
        function() Snacks.picker.lsp_outgoing_calls() end,
        desc = "[o]utgoing",
    },
    -- <leader>s group pickers
    {
        "<leader>sr",
        function() Snacks.picker.recent() end,
        desc = "[r]ecent Files",
    },
    {
        "<leader>sw",
        function() Snacks.picker.grep_word() end,
        desc = "Search Current [w]ord",
        mode = { "n", "v" },
    },
    {
        "<leader>so",
        function() Snacks.picker.grep_buffers() end,
        desc = "Grep [o]pen files",
    },
    {
        "<leader>sc",
        function()
            Snacks.picker.files({
                cwd = vim.fn.stdpath("config"),
                follow = true,
            })
        end,
        desc = "[c]onfig Files",
    },
    {
        "<leader>sh",
        function() Snacks.picker.help() end,
        desc = "[h]elp Tags",
    },
    {
        "<leader>sk",
        function() Snacks.picker.keymaps() end,
        desc = "[k]eymaps",
    },
    {
        "<leader>sm",
        function() Snacks.picker.commands() end,
        desc = "[m]odule Commands",
    },
    {
        "<leader>sd",
        function() Snacks.picker.diagnostics() end,
        desc = "[d]iagnostics",
    },
    {
        "<leader>sS",
        function() Snacks.picker.lsp_workspace_symbols() end,
        desc = "LSP [S]ymbols Workspace",
    },
    {
        "<leader>sp",
        function() Snacks.picker.pickers() end,
        desc = "find [p]ickers",
    },
    {
        "<leader>s.",
        function() Snacks.picker.resume() end,
        desc = "[.] Re-open Last Picker",
    },
}
