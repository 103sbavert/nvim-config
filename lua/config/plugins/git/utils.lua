local M = {}

-- Initialize mappers
M.git_key_mapper = create_keymap_group("[g]it", "<leader>g", { "n", "v" })
M.git_reset_mapper = create_keymap_group("[r]eset", "<leader>gr", { "n", "v" })
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

function M.pick_ref(callback)
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local make_entry = require("telescope.make_entry")
    local conf = require("telescope.config").values
    local Job = require("plenary.job")

    local entry_maker = make_entry.gen_from_git_commits({})
    local results = { "@ <HEAD>", "~1 <staged changes>" }

    Job
        :new({
            command = "git",
            args = { "log", "--pretty=oneline", "--abbrev-commit", "--all" },
            on_exit = function(j)
                vim.list_extend(results, j:result())

                vim.schedule(function()
                    local ref_picker = pickers.new({}, {
                        prompt_title = "Diff Against",
                        finder = finders.new_table({
                            results = results,
                            entry_maker = entry_maker,
                        }),
                        sorter = conf.file_sorter({}),
                        attach_mappings = function(prompt_bufnr)
                            actions.select_default:replace(function()
                                actions.close(prompt_bufnr)
                                callback(
                                    action_state.get_selected_entry().value
                                )
                            end)
                            return true
                        end,
                    })

                    ref_picker:find()
                end)
            end,
        })
        :start()
end

return M
