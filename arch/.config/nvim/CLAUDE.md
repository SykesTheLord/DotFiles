# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration using **lazy.nvim** as the plugin manager. All plugin specs live in `lua/plugins/init.lua` and are loaded automatically. The leader key is `-` and local leader is `_`.

## Plugin Management

- **Install/update plugins:** `:lua vim.pack.update()` — updates all packages declared in `lua/packages.lua`
- **Install LSP servers/tools:** `:Mason` (opens Mason UI), or they auto-install on startup via `mason-tool-installer`
- **Update Treesitter parsers:** `:TSUpdate` (must be run manually after first install)
- **First-time markdown-preview setup:** `cd ~/.local/share/nvim/site/pack/core/opt/markdown-preview.nvim/app && npm install`
- **Reload config changes:** `:source $MYVIMRC` or restart Neovim

## Architecture

### Entry Point
`init.lua` — sets leader keys, bootstraps lazy.nvim, loads all plugins from `lua/plugins/`, sets global options, then requires `keymap`, `ui`, and `workarounds`.

### Key Files
| File | Purpose |
|------|---------|
| `lua/packages.lua` | All plugin declarations via `vim.pack.add()` + eager `packadd` loading |
| `lua/lspConfig.lua` | LSP server configs using `vim.lsp.config`/`vim.lsp.enable` (Neovim 0.11+) |
| `lua/keymap.lua` | Non-plugin keymaps + `vim.snippet` Tab/S-Tab navigation + completion `<CR>` |
| `lua/ui.lua` | Colorscheme, bufferline, opens Neo-tree on startup |
| `lua/workarounds.lua` | Clipboard detection for WSL/Wayland/X11 |
| `lua/configs/snacks.lua` | snacks.nvim setup (all opts + ~50 keybindings, UI toggles, debug globals) |
| `lua/configs/treesitter.lua` | nvim-treesitter + treesitter-context setup |
| `lua/configs/mason.lua` | mason + mason-lspconfig + mason-tool-installer setup |
| `lua/configs/misc.lua` | Small plugin setups: gitsigns, autopairs, which-key, colorizer, lualine, lint, lsp-file-ops, window-picker |
| `lua/configs/formatterConf.lua` | conform.nvim setup — format on save, per-filetype formatters |
| `lua/configs/nvimDapConfig.lua` | DAP adapters for Python, C#, Java, C/C++ |
| `lua/configs/neotreeConfig.lua` | Neo-tree configuration + document symbols autocmd |

### LSP Setup Pattern
`lspConfig.lua` defines servers as a table keyed by server name, each with `cmd`, `filetypes`, and `root_markers`. Uses `vim.lsp.config()` + `vim.lsp.enable()` (Neovim 0.11+). `on_attach` enables built-in LSP completion (`vim.lsp.completion.enable()`) and format-on-save per buffer. Requires Neovim 0.12+.

### Formatting & Linting
- **Formatter:** conform.nvim (`lua/configs/formatterConf.lua`) — runs on `BufWritePre`, uses LSP as fallback. Manual commands: `:Format`, `:FormatWrite`
- **Linter:** nvim-lint — runs on `BufWritePost` via autocmd. Per-filetype linters defined inline in `lua/plugins/init.lua`
- Tools installed via Mason: stylua, black, prettierd, csharpier, clang-format, beautysh, etc.

### Key Bindings Summary
Leader is `-`. Use `<leader>sk` (Snacks keymaps picker) to browse all bindings interactively.

**Navigation/Files:**
- `<leader>e` — Neo-tree toggle, `<leader>o` — reveal in Neo-tree
- `<leader><space>` — Smart find files (Snacks), `<leader>ff` — find files, `<leader>/` — grep
- `<leader>,` / `<leader>fb` — buffers, `<leader>fr` — recent files

**LSP (buffer-local when server attaches):**
- `gd`/`gD` — definition/declaration (Snacks picker), `gr` — references, `gI` — implementation, `gy` — type definition
- `K` — hover docs, `<leader>rn` — rename, `<leader>ca` — code action
- `[d`/`]d` — prev/next diagnostic

**DAP Debugging:**
- `<F5>` continue, `<F10>` step over, `<F11>` step into, `<F12>` step out
- `<leader>du` — toggle DAP UI, `<leader>dr` — DAP REPL
- Breakpoints: `db` toggle, `dc` conditional, `bc` clear all (persistent-breakpoints.nvim)

**Git (Snacks):**
- `<leader>gs` — git status, `<leader>gl` — git log, `<leader>gb` — branches, `<leader>gB` — git browse

**UI Toggles:**
- `<leader>us` — spelling, `<leader>uw` — wrap, `<leader>ud` — diagnostics, `<leader>uh` — inlay hints
- `<leader>z`/`<leader>Z` — zen mode / zoom, `<c-/>` — terminal

## Adding/Modifying LSP Servers
Add a new entry to the `servers` table in `lua/lspConfig.lua`. Mason server installs go in `mason-lspconfig.setup({ ensure_installed = ... })` or `mason-tool-installer.setup({ ensure_installed = ... })` in `lua/configs/mason.lua`.

## Adding New Plugins
Add a `{ src = 'https://github.com/user/repo' }` entry to the `plugins` table in `lua/packages.lua`. The plugin will be installed on the next Neovim startup. Add its setup call to the appropriate config file or create a new one and `require` it in `init.lua`.

## Clipboard
`lua/workarounds.lua` auto-detects the environment (WSL → win32yank, Wayland → wl-copy, X11 → xclip). The distro detection has a specific Neon/Manjaro exception for Wayland usage.
