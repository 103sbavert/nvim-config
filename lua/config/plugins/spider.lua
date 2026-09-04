-- Robust pattern set supporting all standard camelCase/PascalCase variations
local CAMEL_PATTERNS = {
    "^%l?_*%l+%w*%u%w*", -- camelCase with acronyms and prefix (s_camelCase, _camelCase, __camelCase, localHTTPClient)
    "^%u+%w*%l%w*", -- PascalCase with acronyms (PascalCase, HTTPClient)
}

MODES = { "n", "o", "x" }
DEFAULT_QUERY_STR =
    "[(identifier) (property_name) (variable_name) (type_identifier) (name)] @id"

QUERY_CACHE = {}

--- Retrieves or parses the Tree-sitter query for a given language.
---@param lang string The language identifier (e.g., "lua", "python").
---@return vim.treesitter.Query|nil query The parsed Tree-sitter query object, or nil if parsing fails.
local function get_treesitter_query(lang)
    if QUERY_CACHE[lang] ~= nil then
        return QUERY_CACHE[lang]
    end

    --- @type boolean,vim.treesitter.Query?
    local ok, query

    -- Load language-specific spider query from @after/queries/[lang]/spider.scm
    ok, query = pcall(vim.treesitter.query.get, lang, "spider")

    -- Fallback to default query string
    if not ok or not query then
        ok, query = pcall(vim.treesitter.query.parse, lang, DEFAULT_QUERY_STR)
    end

    -- Fallback to raw system queries
    if not ok or not query then
        ok, query = pcall(vim.treesitter.query.get, lang, "highlights")
    end

    QUERY_CACHE[lang] = (ok and query) or false
    return QUERY_CACHE[lang] or nil
end

--- Enables spider motion keymaps for the specified buffer and sets the buffer flag.
---@param bufnr integer Target buffer handle.
local function enable_camel_mode(bufnr)
    vim.b[bufnr].camel_mode_active = true
    for _, motion in ipairs({ "w", "b", "e" }) do
        vim.keymap.set(
            MODES,
            motion,
            function() require("spider").motion(motion) end,
            { buffer = bufnr, desc = "Spider-" .. motion }
        )
    end
end

--- Removes spider motion keymaps for the specified buffer and unsets the buffer flag.
---@param bufnr integer Target buffer handle.
local function disable_camel_mode(bufnr)
    vim.b[bufnr].camel_mode_active = false
    pcall(vim.keymap.del, MODES, "w", { buffer = bufnr })
    pcall(vim.keymap.del, MODES, "b", { buffer = bufnr })
    pcall(vim.keymap.del, MODES, "e", { buffer = bufnr })
end

--- Toggles camel mode on or off for the specified buffer.
---@param bufnr integer Target buffer handle.
local function toggle_camel_mode(bufnr)
    if vim.b[bufnr].camel_mode_active then
        disable_camel_mode(bufnr)
    else
        enable_camel_mode(bufnr)
    end
end

--- Checks whether a given string matches any camelCase or PascalCase pattern.
---@param text string The string to check against configured Lua patterns.
---@return boolean matched True if a match is found, false otherwise.
local function matches_camel_case_pattern(text)
    for _, pattern in ipairs(CAMEL_PATTERNS) do
        if text:find(pattern) then
            return true
        end
    end
    return false
end

--- Scans the top lines of a buffer using Tree-sitter to detect camelCase identifiers.
---@param bufnr integer Target buffer handle.
---@return boolean has_camel True if any captured node contains a camelCase pattern.
local function buffer_contains_camel_case(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return false
    end

    -- Sync tree state
    local trees = parser:parse(true)
    if not trees or #trees == 0 then
        return false
    end

    local lang = parser:lang()
    local query = get_treesitter_query(lang)
    if not query then
        return false
    end

    local root = trees[1]:root()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local max_lines = math.min(line_count, 1000)

    local range_start = line_count > 20 and 10 or 0
    local range_end = math.min(range_start + 200, max_lines)

    while range_start < max_lines do
        for _, node in query:iter_captures(root, bufnr, range_start, range_end) do
            local text = vim.treesitter.get_node_text(node, bufnr)
            if matches_camel_case_pattern(text) then
                return true
            end
        end

        range_start = range_end
        range_end = math.min(range_end * 2, max_lines)
    end

    return false
end

-- Lazy Plugin Spec
--- @type LazySpec
return {
    "chrisgrieser/nvim-spider",
    event = "FileType",
    dependencies = {
        "folke/which-key.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    keys = {
        {
            "<leader>tc",
            function() toggle_camel_mode(vim.api.nvim_get_current_buf()) end,
            desc = "Buffer [c]amelCase Mode",
        },
    },
    config = function()
        -- Re-async camelCase status on filetype change
        local handle_filetype = vim.schedule_wrap(function(bufnr)
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end

            local has_camel = buffer_contains_camel_case(bufnr)
            if has_camel and not vim.b[bufnr].camel_mode_active then
                enable_camel_mode(bufnr)
            elseif not has_camel and vim.b[bufnr].camel_mode_active then
                disable_camel_mode(bufnr)
            end
        end)

        -- Runs detection only if camel_mode_active is currently false
        local handle_save = vim.schedule_wrap(function(bufnr)
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end

            if vim.b[bufnr].camel_mode_active then
                return
            end

            if buffer_contains_camel_case(bufnr) then
                enable_camel_mode(bufnr)
            end
        end)

        local augroup =
            vim.api.nvim_create_augroup("SpiderAutoDetect", { clear = true })

        vim.api.nvim_create_autocmd("FileType", {
            group = augroup,
            callback = function(args) handle_filetype(args.buf) end,
        })

        vim.api.nvim_create_autocmd("BufWritePost", {
            group = augroup,
            callback = function(args) handle_save(args.buf) end,
        })
    end,
}
