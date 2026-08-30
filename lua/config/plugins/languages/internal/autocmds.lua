local lsp_highlight_augroup =
    vim.api.nvim_create_augroup("highlights-lsp-attach", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_highlight_augroup,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if
            client
            and client:supports_method(
                "textDocument/documentHighlight",
                event.buf
            )
        then
            local highlight_augroup = vim.api.nvim_create_augroup(
                "kickstart-lsp-highlight-" .. event.buf,
                { clear = true }
            )

            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = function()
                    local win = vim.api.nvim_get_current_win()
                    if vim.api.nvim_win_get_buf(win) ~= event.buf then
                        return
                    end

                    local request_pos = vim.api.nvim_win_get_cursor(win)
                    local params = vim.lsp.util.make_position_params(
                        win,
                        client.offset_encoding
                    )

                    client:request(
                        "textDocument/documentHighlight",
                        params,
                        function(err, result, ctx, config)
                            if
                                not result
                                or vim.api.nvim_get_current_buf()
                                    ~= event.buf
                            then
                                return
                            end

                            local current_pos = vim.api.nvim_win_get_cursor(win)
                            if
                                current_pos[1] == request_pos[1]
                                and current_pos[2] == request_pos[2]
                            then
                                vim.lsp.buf.clear_references()
                                vim.lsp.handlers["textDocument/documentHighlight"](
                                    err,
                                    result,
                                    ctx,
                                    config
                                )
                            end
                        end,
                        event.buf
                    )
                end,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = function() vim.lsp.buf.clear_references() end,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup(
                    "kickstart-lsp-detach-" .. event.buf,
                    { clear = true }
                ),
                buffer = event.buf,
                callback = function()
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds({
                        group = highlight_augroup,
                    })
                end,
            })
        end

        local function toggle_hints()
            vim.lsp.inlay_hint.enable(
                not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
            )
            return nil, false
        end

        if
            client
            and client:supports_method("textDocument/inlayHint", event.buf)
        then
            if type(map_toggle_key) == "function" then
                map_toggle_key("h", toggle_hints, "Inlay [h]ints")
            end
        end

        if client and client.name == "roslyn" then
            local roslyn_buf_augroup = vim.api.nvim_create_augroup(
                "roslyn-diagnostics-refresh-" .. event.buf,
                { clear = true }
            )
            vim.api.nvim_create_autocmd("InsertLeave", {
                buffer = event.buf,
                group = roslyn_buf_augroup,
                callback = function()
                    local params = {
                        textDocument = vim.lsp.util.make_text_document_params(
                            event.buf
                        ),
                    }
                    client:request(
                        "textDocument/diagnostic",
                        params,
                        nil,
                        event.buf
                    )
                end,
            })
        end
    end,
})
