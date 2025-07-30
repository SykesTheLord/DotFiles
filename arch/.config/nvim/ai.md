Thanks! I’ll begin converting the Neovim config from Vimscript to Lua, switching from vim-plug to Lazy.nvim, improving it where appropriate, grouping it by functionality, and replacing NERDTree with Neo-tree.

I’ll organize the Lua config into separate files (e.g., `plugins.lua`, `lsp.lua`, `telescope.lua`, `ui.lua`, `keymaps.lua`, etc.) for better modularity. I’ll let you know once the converted and improved version is ready.


# Converted Neovim Configuration (vimscript -> Lua with Lazy.nvim)

**Overview:** This new Neovim config uses **Lua** with **Lazy.nvim** for plugin management. It splits the config into logical modules (plugins, LSP, Telescope, UI, keymaps, etc.) and modernizes old plugins and settings. For example, **NERDTree** is replaced by the actively maintained **Neo-tree** plugin, and **vim-gitgutter** is replaced by **gitsigns.nvim** for Git change indicators. We use Neovim’s built-in LSP with Mason for language servers, Treesitter for syntax highlighting, and Lua-native plugins for statusline, commenting, autopairs, etc. All Vimscript `set` and `map` commands are converted to Lua APIs (`vim.opt`, `vim.keymap.set`, etc.) for clarity.

Below is the **full Lua configuration**, organized by file/module:

## `init.lua` – Main initialization

This sets global options, leader keys, and bootstraps Lazy.nvim. If Lazy is not installed, it’s cloned automatically. Then it loads the plugin specs (from the `lua/plugins/` directory) with `require("lazy").setup`. Finally, it sets up some core settings and loads our keymaps module.

```lua
-- Leader keys must be set before plugins are loaded:contentReference[oaicite:6]{index=6}
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Bootstrapping Lazy.nvim if not already installed:contentReference[oaicite:7]{index=7}
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", 
    "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins (reads specs from lua/plugins/*.lua files)
require("lazy").setup({ spec = { import = "plugins" } })

-- General Neovim settings (converted from vimscript 'set' commands)
vim.opt.number = true               -- show line numbers
vim.opt.relativenumber = true       -- relative line numbers
vim.opt.wrap = false                -- no line wrapping
vim.opt.expandtab = true            -- use spaces instead of tabs
vim.opt.shiftwidth = 4              -- indent size = 4
vim.opt.tabstop = 4                 -- tab character width = 4
vim.opt.ignorecase = true           -- case-insensitive search...
vim.opt.smartcase = true            -- ... unless query has capitals
vim.opt.hlsearch = false            -- don't highlight all search matches
vim.opt.mouse = "a"                 -- enable mouse in all modes
vim.opt.clipboard = "unnamedplus"   -- use system clipboard
vim.opt.termguicolors = true        -- true color support

-- Load key mappings (non-plugin specific)
require("keymaps")
```

## `lua/plugins/init.lua` – Plugin specifications

Using **Lazy.nvim**, we declare all plugins in tables. Plugins are grouped by functionality and configured via the `config` or `opts` fields. Lazy.nvim will automatically install and load these plugins. Notable changes:

* **Neo-tree** plugin is added (with its dependencies plenary, devicons, nui) and NERDTree is omitted.
* **gitsigns.nvim** is used for Git integration instead of vim-gitgutter.
* **Mason** and **mason-lspconfig** manage LSP servers; we use Lazy’s recommended setup so they auto-configure on startup.
* Modern Lua plugins for commenting, autopairs, etc., replace older vimscript plugins (e.g., vim-commentary, auto-pairs).

```lua
-- lua/plugins/init.lua
return {

  -- **Plugin Manager and Dependencies**

  -- Lazy.nvim manages itself (already bootstrapped in init.lua)
  { "folke/lazy.nvim", lazy = true },

  -- **Colorscheme** (with high priority so it loads first)
  { "navarasu/onedark.nvim", priority = 1000, config = function()
      require("onedark").setup { style = "darker" }
      require("onedark").load()    -- apply the theme
    end 
  },

  -- **File Explorer** (Neo-tree as NERDTree replacement)
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", 
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",  -- file icons (optional, but recommended)
      "MunifTanjim/nui.nvim"
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        filesystem = { 
          filtered_items = { hide_dotfiles = false, hide_gitignored = true } 
        },
        default_component_configs = {
          indent = { padding = 0 },
          icon = { folder_closed = "", folder_open = "", default = "" },
          modified = { symbol = "[+]" },
        }
      })
      -- Keymaps for Neo-tree (see keymaps.lua for <leader>e and <leader>f)
    end
  },

  -- **LSP and Completion** 
  { "neovim/nvim-lspconfig",  -- Core LSP support
    dependencies = {
      -- Mason to install LSP servers:contentReference[oaicite:12]{index=12}
      { "williamboman/mason.nvim", config = true },
      { "williamboman/mason-lspconfig.nvim", config = true },
      "hrsh7th/cmp-nvim-lsp"   -- LSP source for nvim-cmp
    },
    config = function() require("lsp") end  -- run our LSP setup (in lsp.lua)
  },
  { "simrat39/rust-tools.nvim", dependencies = "neovim/nvim-lspconfig" },  -- Rust enhanced LSP

  -- Autocompletion plugins (nvim-cmp and sources)
  { "hrsh7th/nvim-cmp", event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",            -- snippet engine
      "saadparwaiz1/cmp_luasnip",    -- snippet completions
      "hrsh7th/cmp-buffer",          -- buffer completions
      "hrsh7th/cmp-path",            -- filesystem path completions
      "rafamadriz/friendly-snippets" -- snippet collection
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()  -- load friendly-snippets
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
                      if cmp.visible() then cmp.select_next_item()
                      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                      else fallback() end
                    end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
                      if cmp.visible() then cmp.select_prev_item()
                      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
                      else fallback() end
                    end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, { name = "luasnip" }
        }, {
          { name = "buffer" }, { name = "path" }
        })
      })
    end
  },

  -- **Treesitter** for syntax highlighting and more
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "rust", "python", "markdown" },  -- install these
        highlight = { enable = true },
        indent    = { enable = true },
      })
    end
  },

  -- **Fuzzy Finder** (Telescope)
  { "nvim-telescope/telescope.nvim", branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim",
                     { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 } },
    config = function() require("telescope").setup({}) end
  },

  -- **UI Enhancements**
  { "nvim-lualine/lualine.nvim", dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("lualine").setup({
        options = { theme = "onedark", icons_enabled = true },
        sections = { lualine_c = {"filename"}, lualine_x = {"encoding", "fileformat", "filetype"} }
      })
    end
  },
  { "lukas-reineke/indent-blankline.nvim", event = "BufReadPost",
    opts = { show_trailing_blankline_indent = false, show_current_context = true } 
  },

  -- **Utility Plugins**
  { "tpope/vim-fugitive", cmd = { "Git", "Gedit", "Gstatus", "Gdiffsplit", "Gpush", "Gpull" } },
  { "lewis6991/gitsigns.nvim", event = "BufReadPre",  -- Git change signs (replaces vim-gitgutter):contentReference[oaicite:13]{index=13}
    config = function() require("gitsigns").setup() end 
  },
  { "numToStr/Comment.nvim", keys = { "gc", "gcc", "gbc" },
    config = function() require("Comment").setup() end 
  },
  { "windwp/nvim-autopairs", event = "InsertEnter",
    config = function() require("nvim-autopairs").setup{} end 
  },
  { "folke/which-key.nvim", event = "VeryLazy", config = true }  -- optional: keybinding hints

}
```

**Note:** We use Lazy.nvim’s features to configure plugins succinctly. For instance, setting `config = true` or `opts = {}` will call a plugin’s default setup. We also tie plugin loading to events (InsertEnter, BufRead, etc.) for performance where appropriate.

## `lua/lsp.lua` – LSP and language servers configuration

This module sets up Neovim’s built-in LSP client for various servers, using **mason.nvim** for installer integration. It also defines LSP-related keybindings on attaching to a language server (like *Go to Definition*, *Hover docs*, *Format*, etc.). We use **rust-tools.nvim** for enhanced Rust support (it configures `rust_analyzer` with features like inlay hints). We include completion capabilities from nvim-cmp so LSP can offer completions. This approach replaces any previous CoC/Vim LSP configuration with the native LSP client and Mason for ease of installation.

```lua
-- lua/lsp.lua
local on_attach = function(client, bufnr)
  -- LSP keymaps (only active when LSP attaches to current buffer)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent=true, buffer=bufnr, desc = desc })
  end
  bufmap("n", "K",         vim.lsp.buf.hover, "Hover Documentation")
  bufmap("n", "gd",        vim.lsp.buf.definition, "Go to Definition")
  bufmap("n", "gD",        vim.lsp.buf.declaration, "Go to Declaration")
  bufmap("n", "gi",        vim.lsp.buf.implementation, "Go to Implementation")
  bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
  bufmap("n", "[d",        vim.diagnostic.goto_prev, "Previous Diagnostic")
  bufmap("n", "]d",        vim.diagnostic.goto_next, "Next Diagnostic")
  bufmap("n", "<leader>e", vim.diagnostic.open_float, "Show Diagnostics")
  bufmap("n", "<leader>q", vim.diagnostic.setloclist, "Diagnostics to LocList")
  -- Format on save (if server supports it)
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ async = false, buffer = bufnr }) end
    })
  end
end

-- nvim-cmp integration: advertise completion capabilities to LSP servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
  capabilities = cmp_lsp.default_capabilities()
end

-- Ensure the Mason plugin installed the desired LSP servers 
-- (Mason & mason-lspconfig were auto-setup via lazy.nvim)
local lspconfig = require("lspconfig")
local servers = { "clangd", "pyright", "tsserver", "lua_ls" }
for _, server in ipairs(servers) do
  lspconfig[server].setup({
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

-- Additional setup for specific servers:
-- Lua (Neovim) settings
lspconfig.lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {   -- example of making the Lua language server recognize Neovim globals
    Lua = {
      diagnostics = { globals = { "vim" } }
    }
  }
})

-- Rust (using rust-tools for enhanced capabilities)
local rust_tools_ok, rust_tools = pcall(require, "rust-tools")
if rust_tools_ok then
  rust_tools.setup({
    server = { on_attach = on_attach, capabilities = capabilities }
  })
end
```

## `lua/telescope.lua` – Telescope configuration

This module configures **Telescope** (fuzzy finder) and defines some convenient pickers. It binds common keys for finding files, live grep, etc. The Telescope extension for fzf (if available) is loaded to improve sorting performance.

```lua
-- lua/telescope.lua
local telescope = require("telescope")
telescope.setup{
  defaults = {
    prompt_prefix = "🔍 ",
    selection_caret = "➤ ",
    path_display = {"smart"},
    file_ignore_patterns = { "node_modules", "%.git/" }
  }
}
pcall(telescope.load_extension, "fzf")  -- enable fzf-native, if installed

-- Keymaps for common Telescope functions (see keymaps.lua for <leader> shortcuts)
```

*(Telescope’s keybindings are defined in the global keymaps file for consistency.)*

## `lua/ui.lua` – UI tweaks and appearance

Sets up aesthetic and UI-related configurations. This includes applying the colorscheme, configuring the statusline (lualine), and any other UI modules. In this example, we configured **lualine** in the plugin spec itself and loaded the **onedark** colorscheme via its plugin config. We also enable indent guides via indent-blankline. Additional UI tweaks (if any) can be placed here.

```lua
-- lua/ui.lua
-- (If needed, additional UI config could go here. In this config, most UI plugins 
-- are configured directly in their lazy.nvim spec entries.)
-- Example: ensure the colorscheme is set (if not already done in plugin config)
vim.cmd("colorscheme onedark")
```

## `lua/keymaps.lua` – Custom key mappings

Defines global keymaps for convenience. We use Lua’s `vim.keymap.set()` for mappings, which replaces Vimscript’s `nnoremap`/`vnoremap` syntax with a more readable Lua approach. These include leader shortcuts for file explorer, Telescope, saving/quitting, etc., as well as any other non-LSP mappings. Plugin-specific keys (like toggling Neo-tree or invoking Telescope) are also set here for clarity, leveraging the plugin commands.

```lua
-- lua/keymaps.lua
local map = vim.keymap.set
-- Normal mode leader mappings
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "File Explorer (Neo-tree)" })
map("n", "<leader>o", ":Neotree reveal<CR>", { desc = "Reveal current file in Neo-tree" })
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find Files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live Grep" })
map("n", "<leader>fb", ":Telescope buffers<CR>",    { desc = "List Buffers" })
map("n", "<leader>fh", ":Telescope help_tags<CR>",  { desc = "Search Help" })
-- Convenience mappings
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file (CTRL+S)" })
-- Window navigation (using Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to split below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to split above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
```

**Notes:** We added WhichKey (`which-key.nvim`) as an optional plugin to show a popup of available `<leader>` mappings (this loads on demand). Descriptions in the `vim.keymap.set` options help tools like WhichKey display hints.

---

With this modular Lua setup, the configuration is easier to maintain and extend. We’ve **preserved** all original functionality and **enhanced** it with modern plugins and best practices. For example, using Neo-tree and NvimTree (Lua file explorers) is encouraged now that NERDTree is aging, and gitsigns.nvim provides a superior Git gutter experience. The built-in LSP with Mason simplifies language server management (no more manual LSP installs) and is configured here following recommended patterns. We’ve also transitioned to Lua APIs for settings and mappings (e.g. `vim.opt` and `vim.keymap.set`) for cleaner syntax.

**Sources:**

* Lazy.nvim official docs – bootstrapping and structured plugin config
* Discussion on migrating from init.vim to init.lua (Lua options and keymaps)
* Recommendation to replace NERDTree with modern Lua alternatives (NvimTree/Neo-tree)
* Git integration modernization: vim-gitgutter vs gitsigns.nvim (gitsigns config example)
* Mason + lspconfig usage with Lazy.nvim (auto-setup of LSP servers)

