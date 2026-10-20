--- @type snacks.picker.diagnostics.Config
local dropdown_layout = {
    layout = {
        backdrop = false,
        row = 1,
        width = 0.8,
        min_width = 80,
        height = 0.8,
        border = "none",
        box = "vertical",
        { win = "preview", title = "{preview}", height = 0.7, border = true },
        {
            box = "vertical",
            border = true,
            title = "{title} {live} {flags}",
            title_pos = "center",
            height = 0.5,
            { win = "input", height = 1, border = "bottom" },
            { win = "list", border = "none" },
        },
    },
}

--- @type snacks.picker.diagnostics.Config
local dropdown_conf = {
    layout = dropdown_layout,
    focus = "list",
    show_delay = math.huge,
    win = {
        input = { minimal = true },
        list = { minimal = true },
    },
}

--- @type snacks.picker.diagnostics.Config
local dropdown_input_conf = {
    layout = dropdown_layout,
    focus = "input",
    show_delay = math.huge,
    win = {
        input = { minimal = true },
        list = { minimal = true },
    },
}

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
        desc = "[\\] Toggle Explorer",
    },
    -- File search (top-level shortcuts)
    {
        "<C-/>",
        function() Snacks.terminal.toggle() end,
        desc = "Toggle Terminal",
    },
    {
        "<leader><leader>",
        function() Snacks.picker.buffers() end,
        desc = "[ ] Recent Files",
    },
    {
        "<leader>?",
        function() Snacks.picker.grep(dropdown_input_conf) end,
        desc = "[?] Grep Workspace",
    },
    {
        "<leader>/",
        function() Snacks.picker.lines() end,
        desc = "[/] Grep Buffer",
    },
    {
        "<leader>q",
        function() Snacks.picker.diagnostics_buffer() end,
        desc = "[q]uick Fix Diagnostics",
    },
    -- LSP jump bindings
    {
        "gO",
        function() Snacks.picker.lsp_symbols(dropdown_input_conf) end,
        desc = "[g]oto symb[O]ls",
    },
    {
        "gd",
        function() Snacks.picker.lsp_definitions(dropdown_conf) end,
        desc = "[g]oto [d]efinition",
    },
    {
        "gD",
        function() Snacks.picker.lsp_declarations(dropdown_conf) end,
        desc = "[g]oto [D]eclaration",
    },
    {
        "gr",
        function() Snacks.picker.lsp_references(dropdown_conf) end,
        nowait = true,
        desc = "[g]oto [r]eferences",
    },
    {
        "gI",
        function() Snacks.picker.lsp_implementations(dropdown_conf) end,
        desc = "[g]oto [I]mplementation",
    },
    {
        "gy",
        function() Snacks.picker.lsp_type_definitions(dropdown_conf) end,
        desc = "[g]oto t[y]pe Definition",
    },
    -- <leader>l LSP group
    {
        "<leader>lc",
        function() Snacks.picker.lsp_incoming_calls(dropdown_conf) end,
        desc = "In[c]oming Calls",
    },
    {
        "<leader>lg",
        function() Snacks.picker.lsp_outgoing_calls(dropdown_conf) end,
        desc = "Out[g]oing Calls",
    },
    -- <leader>s group pickers
    {
        "<leader>sr",
        function() Snacks.picker.recent() end,
        desc = "[r]ecent Files",
    },
    {
        "<leader>sw",
        function() Snacks.picker.grep_word(dropdown_conf) end,
        desc = "Search Current [w]ord",
        mode = { "n", "v" },
    },
    {
        "<leader>so",
        function() Snacks.picker.grep_buffers(dropdown_input_conf) end,
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
        function() Snacks.picker.diagnostics(dropdown_conf) end,
        desc = "[d]iagnostics",
    },
    {
        "<leader>sS",
        function() Snacks.picker.lsp_workspace_symbols(dropdown_input_conf) end,
        desc = "LSP [S]ymbols Workspace",
    },
    {
        "<leader>sp",
        function() Snacks.picker.pickers() end,
        desc = "Find [p]ickers",
    },
    {
        "<leader>s.",
        function() Snacks.picker.resume() end,
        desc = "[.] Re-open Last Picker",
    },
    --- Git pickers
    {
        "<leader>gt",
        function() Snacks.picker.git_status() end,
        desc = "s[t]atus",
    },
    {
        "<leader>gl",
        function() Snacks.picker.git_log() end,
        desc = "[l]og",
    },
    {
        "<leader>gD",
        function() Snacks.picker.git_log_file() end,
        desc = "[D]iff file..",
    },
}
