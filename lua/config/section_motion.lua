-- Treesitter [[ ]] [] ][ section motions. A section is a jump target; a run of
-- sections on consecutive lines collapses into one spanning the whole run.

local M = {}

--- @alias Section { srow: integer, scol: integer, erow: integer, ecol: integer }

--- @param node TSNode
--- @return Section covering the whole node
function M.span(node)
    local srow, scol, erow, ecol = node:range()
    return { srow = srow, scol = scol, erow = erow, ecol = ecol }
end

--- @param node TSNode
--- @return Section covering only the node's first line
function M.header(node)
    local srow, scol = node:range()
    return { srow = srow, scol = scol, erow = srow, ecol = scol }
end

--- @param sections Section[] ungrouped, in source order
--- @return Section[] with consecutive-line runs merged into their first section
local function group(sections)
    local grouped = {}
    local prev_end = -2
    for _, s in ipairs(sections) do
        if s.srow > prev_end + 1 then
            grouped[#grouped + 1] = s
        else
            local run = grouped[#grouped]
            run.erow, run.ecol = s.erow, s.ecol
        end
        prev_end = s.erow
    end
    return grouped
end

--- @param sections Section[]
--- @param dir "next_start"|"next_end"|"prev_start"|"prev_end"
--- @param count integer
local function jump(sections, dir, count)
    if #sections == 0 then
        return
    end

    local use_end = dir == "next_end" or dir == "prev_end"
    local forward = dir == "next_start" or dir == "next_end"

    -- nvim_win_get_cursor is (1,0)-indexed; make row 0-based to match TSNode ranges
    local cur = vim.api.nvim_win_get_cursor(0)
    local crow, ccol = cur[1] - 1, cur[2]

    local from, to, step = 1, #sections, 1
    if not forward then
        from, to, step = #sections, 1, -1
    end

    local remaining = count
    local drow, dcol
    for i = from, to, step do
        local s = sections[i]
        local row, col = s.srow, s.scol
        if use_end then
            row, col = s.erow, math.max(s.ecol - 1, 0)
        end

        local passed
        if forward then
            passed = row > crow or (row == crow and col > ccol)
        else
            passed = row < crow or (row == crow and col < ccol)
        end

        if passed then
            drow, dcol = row, col
            remaining = remaining - 1
            if remaining == 0 then
                break
            end
        end
    end

    if not drow then
        return
    end

    vim.cmd("normal! m'") -- push to jumplist
    vim.api.nvim_win_set_cursor(0, { drow + 1, dcol })
end

local maps = {
    ["]]"] = "next_start",
    ["]["] = "next_end",
    ["[["] = "prev_start",
    ["[]"] = "prev_end",
}

--- Installs buffer-local section motions, once per buffer.
--- @param collect fun(): Section[] ungrouped target spans in source order
--- @param guard string buffer variable name guarding against re-mapping on re-source
function M.setup(collect, guard)
    if vim.b[guard] then
        return
    end

    for lhs, dir in pairs(maps) do
        vim.keymap.set(
            { "n", "x", "o" },
            lhs,
            function() jump(group(collect()), dir, vim.v.count1) end,
            {
                buffer = 0,
                silent = true,
                desc = "Section motion (" .. dir .. ")",
            }
        )
    end

    vim.b[guard] = true
end

return M
