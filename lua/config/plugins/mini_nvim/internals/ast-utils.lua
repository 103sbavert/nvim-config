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

-- Cover ignores n_lines (unbounded containment); nearest is bounded by it.
local function as_list(x) return type(x) == "table" and x or { x } end

local shared_cache = nil
local notified_missing = false
local function get_shared()
    if not shared_cache then
        local ok, mod =
            pcall(require, "nvim-treesitter-textobjects.shared")
        if ok then
            shared_cache = mod
        end
    end
    return shared_cache
end

local function notify_missing_once()
    if notified_missing then
        return
    end
    notified_missing = true
    vim.notify(
        "Unable to find Treesitter shared module",
        vim.log.levels.ERROR,
        { title = "Mini AI" }
    )
end

local function get_config()
    local ok, ai = pcall(require, "mini.ai")
    if ok and ai and ai.config then
        return ai.config
    end
    return { n_lines = 50, search_method = "cover_or_nearest" }
end

local function line_offset(bufnr, line_1based)
    local ok, off =
        pcall(vim.api.nvim_buf_get_offset, bufnr, line_1based - 1)
    if ok and type(off) == "number" then
        return off
    end
    return 0
end

--- @return start_b, end_b_excl, from_line, to_line, empty
local function ref_span(bufnr, ref)
    local from_line = ref.from.line
    local to_region = ref.to or ref.from
    local to_line = to_region.line
    local start_b = line_offset(bufnr, from_line) + ref.from.col - 1
    if ref.to == nil then
        return start_b, start_b, from_line, to_line, true
    end
    -- 1-based inclusive to.col equals the 0-based exclusive end byte.
    local end_b = line_offset(bufnr, to_line) + to_region.col
    return start_b, end_b, from_line, to_line, false
end

-- Empty refs exclude the closing byte; exact-equal ranges are rejected
-- so repeats expand to the parent.
local function range_covers(r, start_b, end_b, empty)
    if empty then
        return r[3] <= start_b and start_b < r[6]
    end
    if end_b <= start_b then
        return false
    end
    if not (r[3] <= start_b and end_b <= r[6]) then
        return false
    end
    return r[3] < start_b or end_b < r[6]
end

--- Mini-style n_lines window, applied to nearest fallback only.
local function in_window(r, from_line, to_line, n_lines)
    return r[1] + 1 >= from_line - n_lines
        and r[4] + 1 <= to_line + n_lines
end

local function ask(query_string, bufnr, pos, opts)
    local shared = get_shared()
    if not shared then
        return nil
    end
    local ok, range =
        pcall(shared.textobject_at_point, query_string, "textobjects", bufnr, pos, opts)
    if ok and type(range) == "table" and #range >= 6 then
        return range
    end
    return nil
end

local function search_flags(method)
    if method == "cover" then
        return true, false, false
    elseif method == "cover_or_next" then
        return true, true, false
    elseif method == "cover_or_prev" then
        return true, false, true
    elseif method == "next" then
        return false, true, false
    elseif method == "prev" then
        return false, false, true
    elseif method == "nearest" then
        return false, true, true
    end
    return true, true, true -- "cover_or_nearest" and unknown
end

--- @param query_strings string[]
--- @param bufnr integer
--- @param ref table mini.ai reference_region
--- @return integer[]|nil range Treesitter Range6 (row1,col1,byte1,row2,col2,byte2)
local function best_match(query_strings, bufnr, ref, method, n_lines)
    local shared = get_shared()
    if not shared then
        return nil
    end

    local do_cover, do_ahead, do_behind = search_flags(method)
    local start_b, end_b, from_line, to_line, empty = ref_span(bufnr, ref)
    local pos = { ref.from.line, math.max(0, ref.from.col - 1) }

    if do_cover then
        if empty then
            local best_cover, best_cover_len = nil, nil
            for _, query_string in ipairs(query_strings) do
                local range = ask(query_string, bufnr, pos, {})
                if
                    range
                    and range_covers(range, start_b, end_b, true)
                then
                    local len = range[6] - range[3] -- byte length
                    if
                        not best_cover_len
                        or len < best_cover_len
                        or (
                            len == best_cover_len
                            and range[3] < best_cover[3]
                        )
                    then
                        best_cover, best_cover_len = range, len
                    end
                end
            end
            if best_cover then
                return best_cover
            end
        else
            -- Visual selection: smallest range covering the whole span.
            local best_cover, best_cover_len = nil, nil
            if type(shared.find_best_range) == "function" then
                for _, query_string in ipairs(query_strings) do
                    local ok, range = pcall(
                        shared.find_best_range,
                        bufnr,
                        query_string,
                        "textobjects",
                        function(rg)
                            return range_covers(rg, start_b, end_b, false)
                        end,
                        function(rg)
                            return -((rg[6] - rg[3]) * 4294967296 + rg[3])
                        end
                    )
                    if
                        ok
                        and type(range) == "table"
                        and #range >= 6
                    then
                        local len = range[6] - range[3]
                        if
                            not best_cover_len
                            or len < best_cover_len
                            or (
                                len == best_cover_len
                                and range[3] < best_cover[3]
                            )
                        then
                            best_cover, best_cover_len = range, len
                        end
                    end
                end
            end
            if best_cover then
                return best_cover
            end
            -- Fall through to nearest only if the method allows it.
        end
    end

    if not do_ahead and not do_behind then
        return nil
    end

    local best_near, best_near_dist = nil, nil
    local consider = function(range)
        if not range then
            return
        end
        if range_covers(range, start_b, end_b, empty) then
            return -- cover candidates belong to the cover phase
        end
        if not in_window(range, from_line, to_line, n_lines) then
            return
        end
        local dist = math.min(
            math.abs(range[3] - start_b),
            math.abs(range[6] - end_b)
        )
        if not best_near_dist or dist < best_near_dist then
            best_near, best_near_dist = range, dist
        end
    end

    local look_opts = {}
    if do_ahead then
        table.insert(look_opts, { lookahead = true })
    end
    if do_behind then
        table.insert(look_opts, { lookbehind = true })
    end
    for _, query_string in ipairs(query_strings) do
        for _, opts in ipairs(look_opts) do
            consider(ask(query_string, bufnr, pos, opts))
        end
    end
    return best_near
end

--- @param r integer[] Treesitter Range6 (row1,col1,byte1,row2,col2,byte2)
--- @param bufnr integer
local function range_to_region(r, bufnr)
    local region = {
        from = { line = r[1] + 1, col = r[2] + 1 },
        to = { line = r[4] + 1, col = r[5] },
    }
    if region.to.col == 0 then
        -- End at next line start means trailing newline included: clamp
        -- to the last byte of the previous line.
        region.to.line = region.to.line - 1
        local line = vim.api.nvim_buf_get_lines(
            bufnr,
            region.to.line - 1,
            region.to.line,
            false
        )[1] or ""
        region.to.col = math.max(1, #line)
    end
    return region
end

--- @param id string key into `M.captures`
local function make_textobj(id)
    return function(ai_type, _, opts)
        opts = opts or {}
        local entry = M.captures[id] and M.captures[id][ai_type]
        if not entry then
            return nil
        end
        local query_strings = as_list(entry)
        if #query_strings == 0 then
            return nil
        end

        if not get_shared() then
            notify_missing_once()
            return nil
        end

        local cfg = get_config()
        local method = opts.search_method or cfg.search_method
        local n_lines = opts.n_lines or cfg.n_lines or 50
        local n_times = opts.n_times or 1
        if n_times < 1 then
            return nil
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local ref = opts.reference_region
        if not ref or not ref.from then
            local cursor = vim.api.nvim_win_get_cursor(0)
            ref = { from = { line = cursor[1], col = cursor[2] + 1 } }
        end

        -- n_times searches outward from the previous result.
        local cur_ref = ref
        local range = nil
        for _ = 1, n_times do
            range = best_match(query_strings, bufnr, cur_ref, method, n_lines)
            if not range then
                return nil
            end
            cur_ref = range_to_region(range, bufnr)
        end

        return range_to_region(range, bufnr)
    end
end

M.make_textobj = make_textobj
M.make_decl_textobj = function() return make_textobj("d") end
M.make_func_textobj = function() return make_textobj("f") end
M.make_scope_textobj = function() return make_textobj("s") end

return M
