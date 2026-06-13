require('conform').setup {
    formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        go = { 'gofmt' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        toml = { 'taplo' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        zsh = { 'shfmt' },
    },
    format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
    },
    formatters = {
        stylua = {
            args = { '--indent-type', 'Spaces', '--indent-width', '4', '-' },
        },
        shfmt = {
            args = { '-i', '4', '-ci' },
        },
        prettierd = {
            args = { '--tab-width', '4', '$FILENAME' },
        },
        prettier = {
            args = { '--tab-width', '4', '--stdin-filepath', '$FILENAME' },
        },
        taplo = {
            args = { 'fmt', '--option', 'indent_string=    ', '-' },
        },
    },
}

vim.api.nvim_create_user_command('Conformat', function(args)
    local range = nil
    if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
            start = { args.line1, 0 },
            ['end'] = { args.line2, end_line:len() },
        }
    end
    require('conform').format { astnc = true, lsp_format = 'fallback', range = range }
end, { range = true, desc = 'Format current buffer or visual selection with conform' })
