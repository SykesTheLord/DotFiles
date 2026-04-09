-- lua/configs/misc.lua
-- Small plugin setups that don't require their own file.

-- Window picker (used by neo-tree for "open with window picker")
require("window-picker").setup({
    filter_rules = {
        include_current_win = false,
        autoselect_one = true,
        bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
        },
    },
})

-- LSP-aware file operations (rename/move files updates LSP imports)
require("lsp-file-operations").setup()

-- Git signs in the gutter
require("gitsigns").setup()

-- Auto-close brackets and quotes
require("nvim-autopairs").setup({})

-- Keymap hint popup
require("which-key").setup({})

-- Persist breakpoints across sessions
require("persistent-breakpoints").setup({ load_breakpoints_event = { "BufReadPost" } })

-- Highlight hex/rgb colour codes inline
require("colorizer").setup({
    user_default_options = { names = false, css = true, xterm = true },
})

-- Linter: run per-filetype linters on save
local lint = require("lint")
lint.linters_by_ft = {
    markdown  = { "vale" },
    cs        = { "trivy" },
    terraform = { "tfsec", "trivy" },
    c         = { "trivy" },
    cpp       = { "trivy", "cpplint" },
    cmake     = { "cmakelint" },
    html      = { "htmlhint" },
    java      = { "checkstyle", "trivy" },
    javascript = { "eslint_d" },
    typescript = { "eslint_d" },
    json      = { "jsonlint" },
    python    = { "pylint" },
    sh        = { "shellcheck" },
    sql       = { "sqlfluff" },
    dockerfile = { "trivy" },
}
vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function()
        lint.try_lint()
    end,
})

-- Statusline
require("lualine").setup({
    options = { theme = "dracula", icons_enabled = true },
    sections = {
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
    },
})
