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

    local result = vim.system(staged_cmd_parts, { text = true, cwd = cwd }):wait()

    if result.stderr and vim.trim(result.stderr) ~= "" then
        return true
    end

    return false
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

    vim.system(commit_cmd, {
        cwd = cwd,
        env = env,
        text = true,
    }, function(result)
        if result.code ~= 0 then
            vim.notify(result.stderr, vim.log.levels.ERROR, nopts)
        end
    end)
end

return M
