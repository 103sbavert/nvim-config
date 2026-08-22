---@type LazyKeysSpec[]
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
    -- File search (top-level shortcuts from telescope)
    {
        "<leader>w",
        function() Snacks.picker.files() end,
        desc = "find [w]orkspace files",
    },
    {
        "<leader><leader>",
        function() Snacks.picker.buffers() end,
        desc = "[<leader>] find recent files",
    },
    {
        "<leader>?",
        function() Snacks.picker.grep() end,
        desc = "[?] grep workspace",
    },
    {
        "<leader>/",
        function() Snacks.picker.lines() end,
        desc = "[/] grep buffer",
    },
    -- LSP jump bindings
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
        desc = "[g]oto t[y]pe definition",
    },
    {
        "gai",
        function() Snacks.picker.lsp_incoming_calls() end,
        desc = "[g]oto [a] calls [i]ncoming",
    },
    {
        "gao",
        function() Snacks.picker.lsp_outgoing_calls() end,
        desc = "[g]oto [a] calls [o]utgoing",
    },
    -- <leader>F group pickers
    {
        "<leader>Fr",
        function() Snacks.picker.recent() end,
        desc = "[r]ecent files",
    },
    {
        "<leader>Fg",
        function() Snacks.picker.git_status() end,
        desc = "[g]it status",
    },
    {
        "<leader>Fw",
        function() Snacks.picker.grep_word() end,
        desc = "search current [w]ord",
        mode = { "n", "v" },
    },
    {
        "<leader>Fo",
        function() Snacks.picker.grep_buffers() end,
        desc = "grep [o]pen files",
    },
    {
        "<leader>Fc",
        function()
            Snacks.picker.files({
                cwd = vim.fn.stdpath("config"),
                follow = true,
            })
        end,
        desc = "[c]onfig files",
    },
    {
        "<leader>Fh",
        function() Snacks.picker.help() end,
        desc = "[h]elp tags",
    },
    {
        "<leader>Fk",
        function() Snacks.picker.keymaps() end,
        desc = "[k]eymaps",
    },
    {
        "<leader>Fm",
        function() Snacks.picker.commands() end,
        desc = "[m]odule commands",
    },
    {
        "<leader>Fd",
        function() Snacks.picker.diagnostics() end,
        desc = "[d]iagnostics",
    },
    {
        "<leader>F.",
        function() Snacks.picker.resume() end,
        desc = "[.] resume search",
    },
    {
        "<leader>F?",
        function() Snacks.picker.pickers() end,
        desc = "[?] all pickers",
    },
    -- LSP symbol pickers
    {
        "<leader>Fs",
        function() Snacks.picker.lsp_symbols() end,
        desc = "LSP document [s]ymbols",
    },
    {
        "<leader>FS",
        function() Snacks.picker.lsp_workspace_symbols() end,
        desc = "LSP workspace [S]ymbols",
    },
}
