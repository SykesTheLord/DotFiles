-- Leader keys must be set before plugins are loaded:contentReference[oaicite:6]{index=6}
vim.g.mapleader = "-"
vim.g.maplocalleader = "_"

-- Bootstrapping Lazy.nvim if not already installed:contentReference[oaicite:7]{index=7}
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins (reads specs from lua/plugins/*.lua files)
require("lazy").setup({ spec = { import = "plugins" } })

-- General Neovim settings (converted from vimscript 'set' commands)
vim.wo.number = true            -- show line numbers
vim.opt.relativenumber = false    -- relative line numbers
vim.opt.wrap = false              -- no line wrapping
vim.opt.expandtab = true          -- use spaces instead of tabs
vim.opt.shiftwidth = 4            -- indent size = 4
vim.opt.tabstop = 4               -- tab character width = 4
vim.opt.ignorecase = true         -- case-insensitive search...
vim.opt.smartcase = true          -- ... unless query has capitals
vim.opt.hlsearch = false          -- don't highlight all search matches
vim.opt.mouse = "a"               -- enable mouse in all modes
vim.opt.clipboard = "unnamedplus" -- use system clipboard
vim.opt.termguicolors = true      -- true color support

-- Load key mappings (non-plugin specific)
require("keymap")
require("ui")
require("workarounds")
