-- Leader keys must be set before plugins are loaded
vim.g.mapleader = "-"
vim.g.maplocalleader = "_"

-- Install and load all plugins via vim.pack (Neovim 0.12 built-in)
require("packages")

-- General Neovim settings
vim.wo.number = true
vim.opt.relativenumber = false
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.filetype = "on"
-- Built-in LSP completion (replaces nvim-cmp)
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }

-- Plugin configurations (load order: dependencies before dependents)
require("configs.snacks")        -- early: establishes global Snacks + keybindings
require("configs.treesitter")
require("configs.mason")         -- before lspConfig so servers are registered
require("configs.neotreeConfig")
require("configs.cornConfig")
require("configs.formatterConf")
require("configs.nvimDapConfig")
require("configs.rainbowDelimiters")
require("configs.misc")          -- gitsigns, autopairs, which-key, lint, lualine, etc.
require("lspConfig")             -- after mason

require("keymap")
require("ui")
require("workarounds")
