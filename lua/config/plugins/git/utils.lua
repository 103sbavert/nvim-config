local M = {}

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

    local staged_cmd = table.concat(staged_cmd_parts, " ")

    local staged = vim.fn.system(staged_cmd)

    if vim.trim(staged) == "" then
        return false
    end

    return true
end

function M.git_commit()
    local nopts = { title = "Git" }
    local cwd = vim.fn.getcwd()

    if not has_staged_files() then
        vim.notify("No staged changes to commit", vim.log.levels.WARN, nopts)
        return
    end

    local editor_parts = {
        "nvr",
        "+'set bufhidden=delete'",
        "--servername",
        vim.fn.shellescape(vim.v.servername),
        "--remote-wait",
    }

    local editor = table.concat(editor_parts, " ")
    local env = { GIT_EDITOR = editor }
    local commit_cmd = { "git", "-C", cwd, "commit" }

    vim.fn.jobstart(commit_cmd, {
        cwd = cwd,
        env = env,
        on_stderr = function(_, data)
            local msg = vim.trim(table.concat(data, "\n"))
            if msg == "" then
                return
            end
            vim.notify(msg, vim.log.levels.ERROR, nopts)
        end,
    })
end

return M
