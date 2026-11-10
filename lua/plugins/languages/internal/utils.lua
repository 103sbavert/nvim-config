local M = {}

local golang_analyses = {
    -- Staticcheck Quick Fixes
    QF1005 = true, -- Expand call to math.Pow (https://staticcheck.dev/docs/checks/#QF1005)
    QF1006 = true, -- Lift if+break into loop condition (https://staticcheck.dev/docs/checks/#QF1006)
    QF1007 = true, -- Merge conditional assignment into variable declaration (https://staticcheck.dev/docs/checks/#QF1007)
    QF1011 = true, -- Omit redundant type from variable declaration (https://staticcheck.dev/docs/checks/#QF1011)

    -- Staticcheck Simplifications
    S1002 = true, -- Omit comparison with boolean constant (https://staticcheck.dev/docs/checks/#S1002)
    S1005 = true, -- Drop unnecessary use of the blank identifier (https://staticcheck.dev/docs/checks/#S1005)
    S1006 = true, -- Use 'for { ... }' for infinite loops (https://staticcheck.dev/docs/checks/#S1006)
    S1008 = true, -- Simplify returning boolean expression (https://staticcheck.dev/docs/checks/#S1008)
    S1011 = true, -- Use a single append to concatenate two slices (https://staticcheck.dev/docs/checks/#S1011)
    S1016 = true, -- Use a type conversion instead of manually copying struct fields (https://staticcheck.dev/docs/checks/#S1016)
    S1021 = true, -- Merge variable declaration and assignment (https://staticcheck.dev/docs/checks/#S1021)
    S1025 = true, -- Don't use fmt.Sprintf("%s", x) unnecessarily (https://staticcheck.dev/docs/checks/#S1025)
    S1029 = true, -- Range over the string directly (https://staticcheck.dev/docs/checks/#S1029)

    -- Staticcheck Advanced Analysis
    SA1000 = true, -- Invalid regular expression (https://staticcheck.dev/docs/checks/#SA1000)
    SA1002 = true, -- Invalid format in time.Parse (https://staticcheck.dev/docs/checks/#SA1002)
    SA1003 = true, -- Unsupported argument to functions in encoding/binary (https://staticcheck.dev/docs/checks/#SA1003)
    SA1007 = true, -- Invalid URL in net/url.Parse (https://staticcheck.dev/docs/checks/#SA1007)
    SA1010 = true, -- (*regexp.Regexp).FindAll called with n == 0, which will always return zero results (https://staticcheck.dev/docs/checks/#SA1010)
    SA1011 = true, -- Various methods in the 'strings' package expect valid UTF-8, but invalid input is provided (https://staticcheck.dev/docs/checks/#SA1011)
    SA1014 = true, -- Non-pointer value passed to Unmarshal or Decode (https://staticcheck.dev/docs/checks/#SA1014)
    SA1015 = true, -- Using time.Tick in a way that will leak. Consider using time.NewTicker, and only use time.Tick in tests, commands and endless functions (https://staticcheck.dev/docs/checks/#SA1015)
    SA1018 = true, -- strings.Replace called with n == 0, which does nothing (https://staticcheck.dev/docs/checks/#SA1018)
    SA1028 = true, -- sort.Slice can only be used on slices (https://staticcheck.dev/docs/checks/#SA1028)
    SA1032 = true, -- Wrong order of arguments to errors.Is (https://staticcheck.dev/docs/checks/#SA1032)
    SA4005 = true, -- Field assignment that will never be observed. Did you mean to use a pointer receiver? (https://staticcheck.dev/docs/checks/#SA4005)
    SA4006 = true, -- A value assigned to a variable is never read before being overwritten. Forgotten error check or dead code? (https://staticcheck.dev/docs/checks/#SA4006)
    SA4008 = true, -- The variable in the loop condition never changes, are you incrementing the wrong variable? (https://staticcheck.dev/docs/checks/#SA4008)
    SA4009 = true, -- A function argument is overwritten before its first use (https://staticcheck.dev/docs/checks/#SA4009)
    SA4010 = true, -- The result of append will never be observed anywhere (https://staticcheck.dev/docs/checks/#SA4010)
    SA4012 = true, -- Comparing a value against NaN even though no value is equal to NaN (https://staticcheck.dev/docs/checks/#SA4012)
    SA4015 = true, -- Calling functions like math.Ceil on floats converted from integers doesn't do anything useful (https://staticcheck.dev/docs/checks/#SA4015)
    SA4017 = true, -- Discarding the return values of a function without side effects, making the call pointless (https://staticcheck.dev/docs/checks/#SA4017)
    SA4018 = true, -- Self-assignment of variables (https://staticcheck.dev/docs/checks/#SA4018)
    SA4031 = true, -- Checking never-nil value against nil (https://staticcheck.dev/docs/checks/#SA4031)
    SA5002 = true, -- The empty for loop ('for {}') spins and can block the scheduler (https://staticcheck.dev/docs/checks/#SA5002)
    SA5005 = true, -- The finalizer references the finalized object, preventing garbage collection (https://staticcheck.dev/docs/checks/#SA5005)
    SA5007 = true, -- Infinite recursive call (https://staticcheck.dev/docs/checks/#SA5007)
    SA5012 = true, -- Passing odd-sized slice to function expecting even size (https://staticcheck.dev/docs/checks/#SA5012)
    SA6000 = true, -- Using regexp.Match or related in a loop, should use regexp.Compile (https://staticcheck.dev/docs/checks/#SA6000)
    SA6001 = true, -- Missing an optimization opportunity when indexing maps by byte slices (https://staticcheck.dev/docs/checks/#SA6001)
    SA9001 = true, -- Defers in range loops may not run when you expect them to (https://staticcheck.dev/docs/checks/#SA9001)
    SA9005 = true, -- Trying to marshal a struct with no public fields nor custom marshaling (https://staticcheck.dev/docs/checks/#SA9005)
    SA9008 = true, -- else branch of a type assertion is probably not reading the right value (https://staticcheck.dev/docs/checks/#SA9008)

    -- Staticcheck Style Checks
    ST1005 = true, -- Incorrectly formatted error string (https://staticcheck.dev/docs/checks/#ST1005)
    ST1008 = true, -- A function's error value should be its last return value (https://staticcheck.dev/docs/checks/#ST1008)
    ST1013 = true, -- Should use constants for HTTP error codes, not magic numbers (https://staticcheck.dev/docs/checks/#ST1013)
    ST1015 = true, -- A switch's default case should be the first or last case (https://staticcheck.dev/docs/checks/#ST1015)
    ST1017 = true, -- Don't use Yoda conditions (https://staticcheck.dev/docs/checks/#ST1017)
    ST1020 = true, -- The documentation of an exported function should start with the function's name (https://staticcheck.dev/docs/checks/#ST1020)
    ST1021 = true, -- The documentation of an exported type should start with type's name (https://staticcheck.dev/docs/checks/#ST1021)
    ST1022 = true, -- The documentation of an exported variable or constant should start with variable's name (https://staticcheck.dev/docs/checks/#ST1022)
    ST1023 = true, -- Redundant type in variable declaration (https://staticcheck.dev/docs/checks/#ST1023)

    -- Optional Gopls & Modernizer Analyzers
    slicesdelete = true, -- replace append-based slice deletion with slices.Delete (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_slicesdelete)[cite: 1]
    fieldalignment = true, -- find structs that would use less memory if their fields were sorted (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/fieldalignment)[cite: 1]
    shadow = true, -- check for possible unintended shadowing of variables (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/shadow)[cite: 1]
    appendclipped = true, -- simplify append chains using slices.Concat (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_appendclipped)
    bloop = true, -- replace for-range over b.N with b.Loop (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_bloop)
    errorsastype = true, -- replace errors.As with errors.AsType[T] (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_errorsastype)
}

--- @type table<string, vim.lsp.Config>
M.LsConfig = {
    gitlab_ci_ls = {},
    pyright = {},
    phpactor = {},
    vtsls = {},
    bashls = {},
    markdown_oxide = {},
    tinymist = {
        settings = {
            formatterMode = "typstyle",
            semanticTokens = "enabled",
        },
        before_init = function(_, config)
            local font_paths = require("config.utils").get_env_paths(
                { config.root_dir, vim.fn.getcwd() },
                ".typstrc",
                "TYPST_FONT_PATHS"
            )

            if font_paths then
                config.settings = config.settings or {}
                config.settings.fontPaths = font_paths
            end
        end,
    },
    gopls = {
        settings = {
            gopls = {
                semanticTokens = true,
                hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    compositeLiteralTypes = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
                analyses = golang_analyses,
                staticcheck = true,
            },
        },
    },
    lua_ls = {
        on_init = function(client)
            local lang_utils = require("plugins.languages.internal.utils")

            if
                vim.g.lazy_lua_ls
                or not lang_utils.is_nvim_config(client.workspace_folders)
                or lang_utils.has_lua_config(client.workspace_folders)
            then
                return
            end

            local base_ls_opts = client.config.settings.Lua

            --- @cast base_ls_opts table
            client.config.settings.Lua =
                lang_utils.get_nvim_lua_opts(base_ls_opts)
        end,
        settings = {
            Lua = {
                format = { enable = false },
                diagnostics = { disable = { "missing-fields" } },
            },
        },
    },
}

M.LspFormatGrp =
    vim.api.nvim_create_augroup("GlobalLspFormatting", { clear = true })

--- @class utils.FormatOpts
--- @field client_id? integer Assume this client supports formatting; skip capability checks and pin it.
--- @field async? boolean
--- @field range? { start_line: integer, end_line: integer }

--- Formats bufnr. With `client_id`, formats exclusively through that client
--- Otherwise prefers none-ls when it supports formatting, falling back to any
--- other attached client.
--- @param bufnr integer The buffer to format.
--- @param opts? utils.FormatOpts
function M.FormatBuffer(bufnr, opts)
    opts = opts or {}

    local format_opts = {
        bufnr = bufnr,
        async = opts.async == true,
        formatting_options = {
            tabSize = M.get_indent(bufnr),
            insertSpaces = vim.bo[bufnr].expandtab,
        },
    }

    if opts.client_id then
        format_opts.id = opts.client_id
    else
        local nonels = vim.lsp.get_clients({
            bufnr = bufnr,
            name = "null-ls",
            method = "textDocument/formatting",
        })[1]
        if
            nonels
            and nonels:supports_method("textDocument/formatting", bufnr)
        then
            format_opts.id = nonels.id
        end
    end

    if opts.range then
        format_opts.range = {
            ["start"] = { opts.range.start_line, 0 },
            ["end"] = { opts.range.end_line, 0 },
        }
    end

    vim.lsp.buf.format(format_opts)
end

--- @param key string
--- @param lsp_config LspKeyConfig
--- @param client vim.lsp.Client
--- @param bufnr integer
local function map_if_capable(key, lsp_config, client, bufnr)
    if
        lsp_config.capability
        and not client:supports_method(lsp_config.capability, bufnr)
    then
        return
    end

    local capability = lsp_config.capability

    vim.keymap.set(lsp_config.modes or "n", key, function()
        local live
        if capability then
            live = vim.lsp.get_clients({ bufnr = bufnr, method = capability })
        else
            live = vim.lsp.get_clients({ bufnr = bufnr })
        end

        if #live == 0 then
            vim.notify(
                string.format(
                    "%s: no attached client supports this buffer",
                    lsp_config.description
                ),
                vim.log.levels.WARN
            )
            return
        end

        lsp_config.jump_action(bufnr)
    end, { buffer = bufnr, desc = lsp_config.description })
end

local lsp_jump = require("plugins.languages.internal.actions").lsp_jump

--- @param client vim.lsp.Client
--- @param bufnr integer
function M.map_lsp_actions(client, bufnr)
    for key, config in pairs(lsp_jump) do
        if config.jump_action then
            map_if_capable(key, config, client, bufnr)
        end
    end
end

--- Returns effective indent size for bufnr: buffer-local shiftwidth (or tabstop
--- when shiftwidth=0), cascading to global, with 4 as final safety fallback.
--- @param bufnr integer The buffer handle/number to evaluate.
--- @return integer indent_size The resolved shiftwidth or tabstop indent level.
function M.get_indent(bufnr)
    local sw = vim.bo[bufnr].shiftwidth
    if sw ~= 0 then
        return sw
    end
    -- shiftwidth=0 means "use tabstop"
    local ts = vim.bo[bufnr].tabstop
    if ts ~= 0 then
        return ts
    end
    return 4
end

--- Checks if the given workspace root contains a dedicated Lua configuration file.
--- @param workspace_folders? table[]|string List of workspace folders provided by the LSP client.
--- @return boolean has_config True if `.luarc.json` or `.luarc.jsonc` exists in the workspace root.
function M.has_lua_config(workspace_folders)
    --- @type string
    local dir_path

    if type(workspace_folders) == "string" then
        dir_path = workspace_folders
    elseif
        workspace_folders
        and type(workspace_folders) == "table"
        and #workspace_folders > 0
    then
        dir_path = workspace_folders[1].name
    else
        return false
    end

    return (
        vim.uv.fs_stat(dir_path .. "/.luarc.json") ~= nil
        or vim.uv.fs_stat(dir_path .. "/.luarc.jsonc") ~= nil
    )
end

--- Determines whether the workspace root matches the active Neovim configuration directory.
--- @param workspace_folders? table[] List of workspace folders provided by the LSP client.
--- @return boolean is_nvim True if the workspace path matches standard Neovim config path.
function M.is_nvim_config(workspace_folders)
    if workspace_folders and #workspace_folders > 0 then
        local dir_path = workspace_folders[1].name

        return dir_path == vim.fn.stdpath("config")
    end

    return false
end

--- @type vim.lsp.Config
local nvim_lua_opts = {
    runtime = {
        version = "LuaJIT",
        path = { "lua/?.lua", "lua/?/init.lua" },
    },
    workspace = {
        checkThirdParty = false,
        library = {
            vim.env.VIMRUNTIME,
            vim.fn.stdpath("config"),
            vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt"),
            vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
        },
    },
}

--- Merges Neovim development environment settings into existing Lua language server options.
--- @param base_ls_opts? table Existing Lua settings table to extend.
--- @return table merged_opts Deeply merged LSP settings table prioritizing Neovim config paths.
function M.get_nvim_lua_opts(base_ls_opts)
    if not base_ls_opts or type(base_ls_opts) ~= "table" then
        return vim.deepcopy(nvim_lua_opts)
    end

    return vim.tbl_deep_extend("force", {}, base_ls_opts, nvim_lua_opts)
end

function M.setup_dap_signs()
    local b = vim.g.have_nerd_font

    --- @type table<string, vim.fn.sign_define.dict>
    local signs = {
        ["DapBreakpoint"] = {
            text = b and "" or "●",
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "",
        },
        ["DapBreakpointCondition"] = {
            text = b and "" or "◆",
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "",
        },
        ["DapBreakpointRejected"] = {
            text = b and "󱥸" or "◌",
            texthl = "DapBreakpointRejected",
            linehl = "",
            numhl = "",
        },
        ["DapLogPoint"] = {
            text = b and "󰝶" or "✎",
            texthl = "DapBreakpoint",
            linehl = "",
            numhl = "",
        },
        ["DapStopped"] = {
            text = b and "󰜴" or "➔",
            texthl = "DapStopped",
            linehl = "DapStoppedLine",
            numhl = "DapStoppedLine",
        },
    }

    for name, opts in pairs(signs) do
        pcall(vim.fn.sign_undefine, name)
        vim.fn.sign_define(name, opts)
    end
end

local get_debug_overrides = function()
    local ok, dap = pcall(require, "dap")
    assert(ok, 'Lua module "dap" could not be found')

    return {
        n = {
            ["<leader>dd"] = {
                rhs = dap.continue,
                opts = { desc = "Continue" },
            },
            ["<leader>dx"] = {
                rhs = dap.terminate,
                opts = { desc = "E[x]it" },
            },
            ["<leader>di"] = {
                rhs = dap.step_into,
                opts = { desc = "Step [i]nto" },
            },
            ["<leader>do"] = {
                rhs = dap.step_out,
                opts = { desc = "Step [o]ut" },
            },
            ["<CR>"] = {
                rhs = dap.step_over,
                opts = { desc = "Step over" },
            },
        },
    }
end

function M.add_dap_keymaps()
    for mode, mappings in pairs(get_debug_overrides()) do
        for lhs, map in pairs(mappings) do
            vim.keymap.set(mode, lhs, map.rhs, map.opts)
        end
    end
end

function M.del_dap_keymaps()
    for mode, mappings in pairs(get_debug_overrides()) do
        for lhs, _ in pairs(mappings) do
            pcall(vim.keymap.del, mode, lhs)
        end
    end
end

return M
