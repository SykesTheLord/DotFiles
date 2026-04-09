-- lua/configs/treesitter.lua
-- nvim-treesitter v1 (Neovim 0.12+):
--   - `nvim-treesitter.configs` module no longer exists
--   - Highlight is handled natively by Neovim when parsers are installed
--   - Indent, incremental selection are now Neovim built-ins
--   - Parser management is done via :TSInstall / :TSUpdate

-- Ensure parsers are installed on startup (idempotent — skips already-installed ones).
-- Deferred with vim.schedule so it doesn't block the UI.
vim.schedule(function()
    require("nvim-treesitter.install").install({
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
    })
end)

-- Treesitter context: shows enclosing scope (function/class) at the top of the window
require("treesitter-context").setup({ mode = "cursor", max_lines = 3 })
