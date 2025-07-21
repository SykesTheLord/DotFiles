local vim = vim
local Plug = vim.fn["plug#"]

vim.call("plug#begin")

Plug("williamboman/mason.nvim")
Plug("williamboman/mason-lspconfig.nvim")
Plug("WhoIsSethDaniel/mason-tool-installer.nvim")
Plug("neovim/nvim-lspconfig")
Plug("hrsh7th/nvim-cmp") -- Completion engine
Plug("hrsh7th/cmp-nvim-lsp") -- LSP source for nvim-cmp
Plug("hrsh7th/cmp-buffer") -- Buffer words source
Plug("hrsh7th/cmp-path") -- Filesystem paths source
Plug("hrsh7th/cmp-cmdline") -- Vim command-line source
Plug("L3MON4D3/LuaSnip", { ["tag"] = "v2.*", ["do"] = "make install_jsregexp" }) -- Snippet engine
Plug("saadparwaiz1/cmp_luasnip") -- Snippet source for nvim-cmp
Plug("rafamadriz/friendly-snippets") -- Predefined snippet sets
Plug("ray-x/cmp-sql") -- SQL completion source
Plug("hrsh7th/cmp-nvim-lsp-signature-help") -- Signature help source
Plug("nvim-lua/plenary.nvim") -- Lua utilities (required by Telescope)
Plug("nvim-telescope/telescope.nvim") -- Fuzzy finder
Plug("nvim-treesitter/nvim-treesitter", { ["do"] = ":TSUpdate" }) -- Treesitter syntax
Plug("preservim/nerdtree") -- File tree explorer
Plug("mfussenegger/nvim-dap") -- Debug Adapter Protocol
Plug("Mofiqul/dracula.nvim") -- Colorscheme
Plug("aquasecurity/vim-trivy") -- Trivy integration
Plug("lewis6991/gitsigns.nvim") -- Git change signs
Plug("nvim-treesitter/nvim-treesitter-context") -- Show code context at top
Plug("hiphish/rainbow-delimiters.nvim") -- Rainbow brackets
Plug("ryanoasis/vim-devicons")
Plug("Decodetalkers/csharpls-extended-lsp.nvim")
Plug("nvim-neotest/nvim-nio")
Plug("rcarriga/nvim-dap-ui")
Plug("mfussenegger/nvim-lint")
Plug("mhartington/formatter.nvim")
Plug("tpope/vim-obsession")
Plug("Weissle/persistent-breakpoints.nvim")

vim.call("plug#end")

-- ========== Basic Settings ==========
vim.cmd("set number") -- Show line numbers
vim.cmd("syntax on") -- Enable syntax highlighting
vim.cmd("set mouse=a") -- Enable mouse support
vim.cmd("set hidden") -- Allow unsaved buffers in background
vim.cmd("set cursorline") -- Highlight current line
vim.cmd("set expandtab") -- Use spaces instead of tabs
vim.cmd("set tabstop=4") -- 1 tab = 4 spaces
vim.cmd("set shiftwidth=4") -- Indent by 4 spaces
vim.cmd("set autoindent") -- Copy indent from current line on newline
vim.cmd("set smartindent") -- Smarter autoindent for new lines
vim.cmd("set completeopt=menu,menuone,noselect") -- Better completion menu
vim.cmd("set clipboard=unnamedplus") -- Use system clipboard by default
vim.cmd("set encoding=utf-8") -- Ensure UTF-8 encoding
vim.cmd("set history=5000") -- Increase command history size
vim.cmd("filetype plugin indent on") -- Enable filetype-specific plugins & indent

vim.cmd("silent colorscheme dracula") -- Set colorscheme (requires dracula.nvim)

-- Leader key set to '-'
vim.g.mapleader = "-"

local mason = require("masonConfig")
mason.setup()

local debug_setup = require("debugging")
debug_setup.setup_global()

local snippets = require("snippets")
snippets.setup()

local lspconfig = require("autocmds.lsp_autocmds")
lspconfig.setup()

local lint = require("lintConfig")
lint.setup()

local format = require("formatterConfig")
format.setup()

local start = require("start")
start.setup()

require("autocmds.generalCmds").setup()

local keybinds = require("keybinds")
keybinds.setup()
