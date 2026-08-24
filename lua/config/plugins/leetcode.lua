--- @type LazySpec
return {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
    dependencies = {
        -- include a picker of your choice, see picker section for more details
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    cmd = {
        "Leet",
    },
    --- @type lc.UserConfig
    opts = {
        ---@type string
        arg = nil,

        ---@type lc.lang
        lang = "golang",

        ---@type lc.storage
        storage = {
            home = vim.fs.joinpath(
                vim.env.HOME,
                "Projects/go-leetcode75/solutions"
            ),
            cache = vim.fn.stdpath("cache") .. "/leetcode",
        },

        ---@type table<string, boolean>
        plugins = {
            non_standalone = true,
        },

        ---@type boolean
        logging = true,
        injector = {}, ---@type table<lc.lang, lc.inject>
        cache = {
            update_interval = 60 * 60 * 24 * 7, ---@type integer 7 days
        },
        editor = {
            reset_previous_code = true, ---@type boolean
            fold_imports = true, ---@type boolean
        },

        description = {
            position = "left", ---@type lc.position
            width = "40%", ---@type lc.size
            show_stats = true, ---@type boolean
        },

        hooks = {
            ---@type fun()[]
            ["enter"] = {},

            ---@type fun(question: lc.ui.Question)[]
            ["question_enter"] = {},

            ---@type fun()[]
            ["leave"] = {},
        },

        keys = {
            toggle = { "q" }, ---@type string|string[]
            confirm = { "<CR>" }, ---@type string|string[]

            reset_testcases = "r", ---@type string
            use_testcase = "U", ---@type string
            focus_testcases = "H", ---@type string
            focus_result = "L", ---@type string
        },

        ---@type lc.highlights
        theme = {},

        ---@type boolean
        image_support = false,
    },
}
