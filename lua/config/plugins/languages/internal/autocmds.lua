local function highlight_cursor_symbol(client, bufnr)
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) ~= bufnr then
        return
    end

    local request_pos = vim.api.nvim_win_get_cursor(win)
    local params =
        vim.lsp.util.make_position_params(win, client.offset_encoding)

    client:request(
        "textDocument/documentHighlight",
        params,
        function(err, result, ctx, config)
            if not result or vim.api.nvim_get_current_buf() ~= bufnr then
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
        bufnr
    )
end

--- @param client vim.lsp.Client
--- @param bufnr integer
local function on_client_attach(client, bufnr)
    require("config.plugins.languages.internal.utils").map_lsp_actions(
        client,
        bufnr
    )

    if client:supports_method("textDocument/documentHighlight", bufnr) then
        local highlight_augroup = vim.api.nvim_create_augroup(
            "kickstart-lsp-highlight-" .. bufnr,
            { clear = true }
        )

        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = bufnr,
            group = highlight_augroup,
            callback = function() highlight_cursor_symbol(client, bufnr) end,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = bufnr,
            group = highlight_augroup,
            callback = function() vim.lsp.buf.clear_references() end,
        })

        vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup(
                "kickstart-lsp-detach-" .. bufnr,
                { clear = true }
            ),
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({
                    group = highlight_augroup,
                })
            end,
        })
    end

    local toggle_hints = function()
        vim.lsp.inlay_hint.enable(
            not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        )
        return nil, false
    end

    if client:supports_method("textDocument/inlayHint", bufnr) then
        if type(map_toggle_key) == "function" then
            map_toggle_key("h", toggle_hints, "Inlay [h]ints")
        end
    end

    if client.name == "roslyn" then
        local roslyn_buf_augroup = vim.api.nvim_create_augroup(
            "roslyn-diagnostics-refresh-" .. bufnr,
            { clear = true }
        )
        vim.api.nvim_create_autocmd("InsertLeave", {
            buffer = bufnr,
            group = roslyn_buf_augroup,
            callback = function()
                local params = {
                    textDocument = vim.lsp.util.make_text_document_params(
                        bufnr
                    ),
                }
                client:request("textDocument/diagnostic", params, nil, bufnr)
            end,
        })
    end
end

local lsp_highlight_augroup =
    vim.api.nvim_create_augroup("highlights-lsp-attach", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_highlight_augroup,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if not client then
            return
        end

        on_client_attach(client, event.buf)
    end,
})

-- Servers that perform dynamic registration may register capabilities any
-- time after LspAttach. Re-run the on-attach logic for every buffer the
-- client is already attached to when that happens.
-- See: https://neovim.io/doc/user/lsp.html (LspAttach)
vim.lsp.handlers["client/registerCapability"] = (function(overridden)
    return function(err, res, ctx)
        local result = overridden(err, res, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then
            return result
        end

        for bufnr, _ in pairs(client.attached_buffers) do
            on_client_attach(client, bufnr)
        end

        return result
    end
end)(vim.lsp.handlers["client/registerCapability"])
