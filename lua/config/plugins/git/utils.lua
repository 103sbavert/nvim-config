local M = {}

-- Initialize mappers
M.git_key_mapper = create_keymap_group("[g]it", "<leader>g", { "n", "v" })
M.navigate_bw_mapper = create_keymap_group("[ backwards", "[", { "n", "v" })
M.navigate_fw_mapper = create_keymap_group("] forwards", "]", { "n", "v" })

local function has_staged_files()
    local cwd = vim.fn.getcwd()

    local staged_cmd_parts = {
        "git",
        "-C",
        vim.fn.shellescape(cwd),
        "diff",
        "--cached",
        "--name-only",
    }

    local result = vim.system(staged_cmd_parts, { text = true, cwd = cwd })
        :wait()

    if result.stderr and vim.trim(result.stderr) ~= "" then
        return true
    end

    return false
end

function M.commit()
    local nopts = { title = "Git" }
    local cwd = vim.fn.getcwd()

    if not has_staged_files() then
        vim.notify("No staged changes to commit", vim.log.levels.WARN, nopts)
        return
    end

    local env = { GIT_EDITOR = vim.env.GIT_EDITOR }
    local commit_cmd = { "git", "-C", cwd, "commit" }

    vim.system(commit_cmd, {
        cwd = cwd,
        env = env,
        text = true,
    }, function(result)
        if result.code == 0 then
            vim.notify("Changes committed", nopts)
        else
            vim.notify("Changes not committed", vim.log.levels.ERROR, nopts)
            vim.notify(result.stderr, vim.log.levels.ERROR, nopts)
        end
    end)
end

local snacks_picker = require("snacks.picker")
local snacks_align = snacks_picker.util.align

local function get_git_status()
    local result = vim.system({ "git", "status", "--porcelain" }):wait()
    local staged, unstaged, untracked = 0, 0, 0
    local files = {}

    if result.code == 0 and result.stdout then
        for line in
            vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true })
        do
            local x = line:sub(1, 1)
            local y = line:sub(2, 2)
            local file = line:sub(4)

            if file:find(" -> ") then
                file = file:match("->%s*(.*)$") or file
            end
            table.insert(files, file)

            if x ~= " " and x ~= "?" then
                staged = staged + 1
            end
            if y ~= " " and y ~= "?" then
                unstaged = unstaged + 1
            end
            if x == "?" and y == "?" then
                untracked = untracked + 1
            end
        end
    end
    return staged, unstaged, untracked, files
end

local function index_formatter(item, picker)
    return {
        { snacks_align(item.name, 15), "SnacksPickerLabel" },
        {
            snacks_align("A " .. item.staged .. " ", 6),
            "SnacksPickerGitAdd",
        },
        {
            snacks_align("M " .. item.unstaged .. " ", 6),
            "SnacksPickerGitChange",
        },
        {
            snacks_align("U " .. item.untracked .. " ", 6),
            "SnacksPickerComment",
        },
        { " " },
    }
end

local function git_log_formatter(head_sha, item, picker)
    local formatted_item = require("snacks.picker.format").git_log(item, picker)
    local is_head = item.commit and vim.startswith(head_sha, item.commit)
    local symbol = is_head and "@" or ""
    local hl = is_head and "SnacksPickerSpecial" or nil

    table.insert(formatted_item, 3, { snacks_align(symbol, 4), hl })
    return formatted_item
end

function M.pick_diff_base(callback)
    local head_short_sha =
        vim.trim(vim.system({ "git", "rev-parse", "HEAD" }):wait().stdout)

    snacks_picker.pick({
        multi = {
            {
                preview = "git_diff",
                finder = function()
                    local staged, unstaged, untracked, files = get_git_status()
                    local text = table.concat(files, "\n")
                    return {
                        {
                            name = "Index",
                            commit = "Index",
                            text = text,
                            staged = staged,
                            unstaged = unstaged,
                            untracked = untracked,
                        },
                    }
                end,
                format = index_formatter,
            },
            {
                preview = "git_show",
                finder = "git_log",
                format = function(item, picker)
                    return git_log_formatter(head_short_sha, item, picker)
                end,
            },
        },
        confirm = function(picker, item)
            picker:close()

            local ref = item and (item.name or item.commit or item.branch)
            if not ref then
                vim.notify(
                    "No branch or commit found",
                    vim.log.levels.WARN,
                    { title = "Gitsigns" }
                )
                return
            end

            callback(ref)
        end,
    })
end

return M
