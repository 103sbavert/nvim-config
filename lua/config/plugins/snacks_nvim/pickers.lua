--- @return snacks.picker.diagnostics.Config
local get_ivy_split = function()
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

--- @return snacks.picker.diagnostics.Config
local function get_dropdown_conf()
    local dropdown =
        vim.deepcopy(require("snacks.picker.config.layouts").dropdown)

    dropdown.layout[1].height = 0.65
    dropdown.layout.width = 0.8

    return {
        layout = dropdown,
        focus = "list",
        show_delay = math.huge,
        win = {
            input = { minimal = true },
            list = { minimal = true },
        },
    }
end

local function open_split(source) Snacks.picker[source](get_dropdown_conf()) end

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
        function() open_split("grep") end,
        desc = "[?] Grep Workspace",
    },
    {
        "<leader>/",
        function() Snacks.picker.lines() end,
        desc = "[/] Grep Buffer",
    },
    {
        "<leader>q",
        function()
            Snacks.picker.diagnostics_buffer({
                layout = "ivy_split",
                jump = { close = false },
                auto_close = false,
                focus = "list",
                win = {
                    input = { minimal = true },
                    list = { minimal = true },
                },
            })
        end,
        desc = "[q]uick Fix Diagnostics",
    },
    -- LSP jump bindings
    {
        "gs",
        function() open_split("lsp_symbols") end,
        desc = "[g]oto [s]ymbols",
    },
    {
        "gd",
        function() open_split("lsp_definitions") end,
        desc = "[g]oto [d]efinition",
    },
    {
        "gD",
        function() open_split("lsp_declarations") end,
        desc = "[g]oto [D]eclaration",
    },
    {
        "gr",
        function() open_split("lsp_references") end,
        nowait = true,
        desc = "[g]oto [r]eferences",
    },
    {
        "gI",
        function() open_split("lsp_implementations") end,
        desc = "[g]oto [I]mplementation",
    },
    {
        "gy",
        function() open_split("lsp_type_definitions") end,
        desc = "[g]oto t[y]pe Definition",
    },
    -- <leader>l LSP group
    {
        "<leader>lc",
        function() open_split("lsp_incoming_calls") end,
        desc = "In[c]oming Calls",
    },
    {
        "<leader>lg",
        function() open_split("lsp_outgoing_calls") end,
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
        function() open_split("grep_word") end,
        desc = "Search Current [w]ord",
        mode = { "n", "v" },
    },
    {
        "<leader>so",
        function() open_split("grep_buffers") end,
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
        function() open_split("diagnostics") end,
        desc = "[d]iagnostics",
    },
    {
        "<leader>sS",
        function() open_split("lsp_workspace_symbols") end,
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
