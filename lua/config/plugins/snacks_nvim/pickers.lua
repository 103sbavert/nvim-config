--- @return snacks.picker.diagnostics.Config
local get_ivy_split_conf = function()
    return {
        layout = "ivy_split",
        jump = { close = false },
        auto_close = false,
        focus = "list",
        win = {
            input = { minimal = true },
            list = { minimal = true },
        },
    }
end

--- @param focus? "input" | "list"
--- @return snacks.picker.diagnostics.Config
local function get_dropdown_conf(focus)
    local dropdown =
        vim.deepcopy(require("snacks.picker.config.layouts").dropdown)

    dropdown.layout[1].height = 0.7
    dropdown.layout[2].height = 0.5
    dropdown.layout.width = 0.8
    dropdown.layout.height = 0.8

    return {
        layout = dropdown,
        focus = focus or "list",
        show_delay = math.huge,
        win = {
            input = { minimal = true },
            list = { minimal = true },
        },
    }
end

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
        function() Snacks.picker.grep(get_dropdown_conf("input")) end,
        desc = "[?] Grep Workspace",
    },
    {
        "<leader>/",
        function() Snacks.picker.lines() end,
        desc = "[/] Grep Buffer",
    },
    {
        "<leader>q",
        function() Snacks.picker.diagnostics_buffer(get_ivy_split_conf()) end,
        desc = "[q]uick Fix Diagnostics",
    },
    -- LSP jump bindings
    {
        "gs",
        function() Snacks.picker.lsp_symbols(get_dropdown_conf()) end,
        desc = "[g]oto [s]ymbols",
    },
    {
        "gd",
        function() Snacks.picker.lsp_definitions(get_dropdown_conf()) end,
        desc = "[g]oto [d]efinition",
    },
    {
        "gD",
        function() Snacks.picker.lsp_declarations(get_dropdown_conf()) end,
        desc = "[g]oto [D]eclaration",
    },
    {
        "gr",
        function() Snacks.picker.lsp_references(get_dropdown_conf()) end,
        nowait = true,
        desc = "[g]oto [r]eferences",
    },
    {
        "gI",
        function() Snacks.picker.lsp_implementations(get_dropdown_conf()) end,
        desc = "[g]oto [I]mplementation",
    },
    {
        "gy",
        function() Snacks.picker.lsp_type_definitions(get_dropdown_conf()) end,
        desc = "[g]oto t[y]pe Definition",
    },
    -- <leader>l LSP group
    {
        "<leader>lc",
        function() Snacks.picker.lsp_incoming_calls(get_dropdown_conf()) end,
        desc = "In[c]oming Calls",
    },
    {
        "<leader>lg",
        function() Snacks.picker.lsp_outgoing_calls(get_dropdown_conf()) end,
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
        function() Snacks.picker.grep_word(get_dropdown_conf()) end,
        desc = "Search Current [w]ord",
        mode = { "n", "v" },
    },
    {
        "<leader>so",
        function() Snacks.picker.grep_buffers(get_dropdown_conf("input")) end,
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
        function() Snacks.picker.diagnostics(get_dropdown_conf()) end,
        desc = "[d]iagnostics",
    },
    {
        "<leader>sS",
        function() Snacks.picker.lsp_workspace_symbols(get_dropdown_conf()) end,
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
}
