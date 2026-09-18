local M = {}

M.captures = {
    -- Variable declarations / assignments
    d = { a = "@assignment.outer", i = "@assignment.rhs" },

    -- Function implementation bodies
    f = { a = "@function.outer", i = "@function.inner" },

    -- Blocks, loops, conditionals
    s = {
        a = { "@block.outer", "@loop.outer", "@conditional.outer" },
        i = { "@block.inner", "@loop.inner", "@conditional.inner" },
    },
}

local function as_list(x) return type(x) == "table" and x or { x } end

--- @param query_strings string[]
--- @param bufnr integer
--- @param pos { [1]: integer, [2]: integer }
--- @return integer[]|nil range Treesitter Range6 (row1,col1,byte1,row2,col2,byte2)
local function best_match(query_strings, bufnr, pos)
    local has_shared, shared =
        pcall(require, "nvim-treesitter-textobjects.shared")
    if not has_shared then
        vim.notify(
            "Unable to find Treesitter shared module",
            vim.log.levels.ERROR,
            { title = "Mini AI" }
        )
        return nil
    end

    local best_cover, best_cover_len = nil, nil
    for _, query_string in ipairs(query_strings) do
        local ok, range = pcall(
            shared.textobject_at_point,
            query_string,
            "textobjects",
            bufnr,
            pos,
            {}
        )

        if ok and range then
            local len = range[6] - range[3] -- byte length
            if best_cover_len == nil or len < best_cover_len then
                best_cover, best_cover_len = range, len
            end
        end
    end

    if best_cover then
        return best_cover
    end

    local row = pos[1] - 1
    local best_near, best_near_dist = nil, nil
    local consider = function(range)
        if not range then
            return
        end
        local dist =
            math.min(math.abs(range[1] - row), math.abs(range[4] - row))
        if best_near_dist == nil or dist < best_near_dist then
            best_near, best_near_dist = range, dist
        end
    end

    for _, query_string in ipairs(query_strings) do
        local ok_ahead, range_ahead = pcall(
            shared.textobject_at_point,
            query_string,
            "textobjects",
            bufnr,
            pos,
            { lookahead = true }
        )

        if ok_ahead then
            consider(range_ahead)
        end

        local ok_behind, range_behind = pcall(
            shared.textobject_at_point,
            query_string,
            "textobjects",
            bufnr,
            pos,
            { lookbehind = true }
        )
        if ok_behind then
            consider(range_behind)
        end
    end
    return best_near
end

--- @param r integer[] Treesitter Range6 (row1,col1,byte1,row2,col2,byte2)
local function range_to_region(r)
    local region = {
        from = { line = r[1] + 1, col = r[2] + 1 },
        to = { line = r[4] + 1, col = r[5] },
    }
    if region.to.col == 0 then
        region.to.line = region.to.line - 1
        region.to.col = vim.fn.col({ region.to.line, "$" })
    end
    return region
end

--- @param id string key into `M.captures`
local function make_textobj(id)
    return function(ai_type)
        local query_strings =
            as_list(M.captures[id] and M.captures[id][ai_type])
        if #query_strings == 0 then
            return nil
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local pos = vim.api.nvim_win_get_cursor(0)

        local range = best_match(query_strings, bufnr, pos)
        if not range then
            return nil
        end

        return range_to_region(range)
    end
end

M.make_decl_textobj = function() return make_textobj("d") end
M.make_func_textobj = function() return make_textobj("f") end
M.make_scope_textobj = function() return make_textobj("s") end

return M
