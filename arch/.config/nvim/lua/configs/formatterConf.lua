local conform = require("conform")

conform.setup({
    log_level = vim.log.levels.WARN,
    notify_on_error = true,

    -- Map filetypes to their formatter(s)
    formatters_by_ft = {
        lua = { "stylua" },

        cs = { "csharpier" },

        c = { "clang-format" },
        cpp = { "clang-format" },
        java = { "google-java-format" },

        cmake = { "cmake_format" },

        -- Run prettierd if available, otherwise fall back to prettier
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },

        sh = { "beautysh" },
        zsh = { "beautysh" },

        sql = { "sql_formatter" },

        python = { "black" },
    },

    -- Custom formatter overrides
    formatters = {
        -- Make beautysh respect your current indent settings (shiftwidth/expandtab).
        -- With stdin=false, conform writes to a temp file and expects the formatter to edit it in-place.
        beautysh = {
            stdin = false,
            args = function(_, ctx)
                local shiftwidth = vim.bo[ctx.buf].shiftwidth
                local expandtab = vim.bo[ctx.buf].expandtab

                if not expandtab then
                    shiftwidth = 0
                end

                return { "-i", tostring(shiftwidth), "$FILENAME" }
            end,
        },
    },

    -- Format before saving the file to disk
    format_on_save = {
        timeout_ms = 1000,
        lsp_format = "fallback",
    },
})

-- Optional: make gq use conform's formatting expression
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- Backwards-compatible commands (from formatter.nvim)
vim.api.nvim_create_user_command("Format", function()
    conform.format({ lsp_format = "fallback" })
end, {})

vim.api.nvim_create_user_command("FormatWrite", function()
    conform.format({ lsp_format = "fallback" })
    vim.cmd("write")
end, {})
