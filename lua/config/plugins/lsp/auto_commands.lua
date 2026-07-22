local lsp_highlight_augroup = vim.api.nvim_create_augroup("highlights-lsp-attach", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_highlight_augroup,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client:supports_method("textDocument/documentHighlight", event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })

            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                callback = function(event2)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds({ group = highlight_augroup, buffer = event2.buf })
                end,
            })
        end

        local function toggle_hints()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            return nil, false
        end

        if client and client:supports_method("textDocument/inlayHint", event.buf) then
            map_toggle_key("h", toggle_hints, "Inlay [h]ints")
        end
    end,
})

local roslyn_augroup = vim.api.nvim_create_augroup("roslyn-diagnostics-refresh", { clear = true })

-- See https://github.com/seblyng/roslyn.nvim/wiki/Home/6a92a1d9370a022d2f4545a1480b02416bb1e57e#diagnostic-refresh
vim.api.nvim_create_autocmd({ "InsertLeave", "CursorHoldI", "CursorHold" }, {
    group = roslyn_augroup,
    pattern = { "**/*.cs", "*.cs" },
    callback = function()
        local clients = vim.lsp.get_clients({ name = "roslyn" })
        if not clients or #clients == 0 then
            return
        end

        local client = clients[1]
        for buf in pairs(client.attached_buffers) do
            local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
            client:request("textDocument/diagnostic", params, nil, buf)
        end
    end,
})
