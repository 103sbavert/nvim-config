local utils = require("config.utils")

local workspaces = {
    { name = "personal", path = "~/vaults/personal" },
    { name = "work", path = "~/vaults/work" },
}

--- @type string[]
local patterns = {}
local function get_patterns(spaces)
    if #patterns == #spaces * 2 then
        return patterns
    end

    for _, ws in ipairs(spaces) do
        table.insert(
            patterns,
            vim.fs.joinpath(vim.fs.normalize(ws.path), "*.md")
        )
        table.insert(
            patterns,
            vim.fs.joinpath(vim.fs.normalize(ws.path), "/**/*.md")
        )
    end
    return patterns
end

local event = {}

local function get_events(patterns_tbl)
    if #event == #patterns_tbl * 2 then
        return event
    end

    for _, pattern in ipairs(patterns_tbl) do
        table.insert(event, "BufReadPre " .. pattern)
        table.insert(event, "BufNewFile " .. pattern)
    end
    return event
end

--- @type LazySpec
return {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    event = get_events(get_patterns(workspaces)),
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
        legacy_commands = false,
        workspaces = workspaces,
    },
    config = function(_, opts)
        require("obsidian").setup(opts)

        local augrp =
            vim.api.nvim_create_augroup("ObsidianConceal", { clear = true })

        vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
            group = augrp,
            pattern = get_patterns(workspaces),
            callback = function() vim.opt_local.conceallevel = 2 end,
        })

        -- replay for buf that triggered lazy-load, only this group's aucmds
        local real_path = utils.get_current_file()
        if real_path then
            vim.api.nvim_exec_autocmds({ "BufReadPre", "BufNewFile" }, {
                group = augrp,
                pattern = vim.fs.normalize(real_path),
            })
        end
    end,
}
