" Neovim 0.10.4 init.vim - Updated for WSL environment

" ========== Plugin Installation (vim-plug) ==========
call plug#begin('~/.local/share/nvim/plugged')
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'WhoIsSethDaniel/mason-tool-installer.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'                       " Completion engine
Plug 'hrsh7th/cmp-nvim-lsp'                   " LSP source for nvim-cmp
Plug 'hrsh7th/cmp-buffer'                     " Buffer words source
Plug 'hrsh7th/cmp-path'                       " Filesystem paths source
Plug 'hrsh7th/cmp-cmdline'                    " Vim command-line source
Plug 'L3MON4D3/LuaSnip', {'tag': 'v2.*', 'do': 'make install_jsregexp'}                      " Snippet engine
Plug 'saadparwaiz1/cmp_luasnip'               " Snippet source for nvim-cmp
Plug 'rafamadriz/friendly-snippets'           " Predefined snippet sets
Plug 'ray-x/cmp-sql'                          " SQL completion source
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'    " Signature help source
Plug 'nvim-lua/plenary.nvim'                  " Lua utilities (required by Telescope)
Plug 'nvim-telescope/telescope.nvim'          " Fuzzy finder
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " Treesitter syntax
Plug 'preservim/nerdtree'                     " File tree explorer
Plug 'mfussenegger/nvim-dap'                  " Debug Adapter Protocol
Plug 'Mofiqul/dracula.nvim'                   " Colorscheme
Plug 'aquasecurity/vim-trivy'                 " Trivy integration
Plug 'lewis6991/gitsigns.nvim'                " Git change signs
Plug 'nvim-treesitter/nvim-treesitter-context' " Show code context at top
Plug 'hiphish/rainbow-delimiters.nvim'        " Rainbow brackets
Plug 'ryanoasis/vim-devicons'
Plug 'Decodetalkers/csharpls-extended-lsp.nvim' 
Plug 'mfussenegger/nvim-dap'
Plug 'nvim-neotest/nvim-nio'
Plug 'rcarriga/nvim-dap-ui'
Plug 'mfussenegger/nvim-lint'
Plug 'mhartington/formatter.nvim'
Plug 'tpope/vim-obsession'
Plug 'Weissle/persistent-breakpoints.nvim'
call plug#end()

" ========== Basic Settings ==========
set number              " Show line numbers
syntax on               " Enable syntax highlighting
" set guifont=CaskaydiaCove\ Nerd\ Font 11
set mouse=a             " Enable mouse support
set hidden              " Allow unsaved buffers in background
set cursorline          " Highlight current line
set expandtab           " Use spaces instead of tabs
set tabstop=4           " 1 tab = 4 spaces
set shiftwidth=4        " Indent by 4 spaces
set autoindent          " Copy indent from current line on newline
set smartindent         " Smarter autoindent for new lines
set completeopt=menu,menuone,noselect  " Better completion menu
set clipboard=unnamedplus            " Use system clipboard by default
set encoding=utf-8      " Ensure UTF-8 encoding
set history=5000        " Increase command history size
filetype plugin indent on  " Enable filetype-specific plugins & indent

colorscheme dracula     " Set colorscheme (requires dracula.nvim)

" Leader key set to '-'"
let mapleader = "-"

" ========== LSP, Mason, and Completion Setup ==========
lua <<EOF
-- Mason Package Manager setup
require("mason").setup()

-- Mason-Tool-Installer
require('mason-tool-installer').setup {
    ensure_installed = {
        'trivy', -- Linter for Various issues
        'csharpier', -- C# formatter
        'netcoredbg', -- C# debugger
        'black', -- Python formatter
        'debugpy', -- Python debugger
        'pylint', -- Python Linter
        'eslint_d',-- Javascript and TypeScript linter
        'jsonlint', -- JSON linter
        'beautysh', -- Bash, Csh, Zsh formatter 
        'shellcheck', -- Bash linter
        'prettierd', -- Angular, CSS, Flow, GraphQL, HTML, JSON, JSX, JavaScript, LESS, Markdown, SCSS, TypeScript, Vue, and YAML formatter
        'java-debug-adapter', -- Java debugger
        'clang-format', -- C, C++, JSON, Java, and JavaScript formatter
        'stylua', -- Lua formatter
        'luacheck', -- Lua Linter 
        'cmakelang', -- CMake formatter and linter
        'sqlfluff', -- SQL linter
        'sql-formatter', -- SQL formatter
        'vale', -- Markdown linter
        'tfsec', -- Terraform linter
        'cpplint', -- C++ linter
        'cmakelint', -- CMake linter
        'htmlhint', -- HTML linter
        'checkstyle', -- Java linter
        'cpptools' -- C. C++ and Rust debuggecpptools' -- C. C++ and Rust debugger
    },
    automatic_installation = true,
    auto_update = true,
}

-- Mason-LSPconfig integration (automatic LSP installation)
require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd",
        "eslint",
        "jedi_language_server",
        "jsonls",
        "yamlls",
        -- "omnisharp", -- (Handled separately below)
        "terraformls",
        "dockerls",
        "bashls",
        "docker_compose_language_service",
        "jdtls",
        "lua_ls",
        "marksman",
        "powershell_es",
        "cmake",
        "vimls",
        "bicep",
        "sqls",
    },
    automatic_installation = true,
})

-- Force CSharp-ls version
local registry = require("mason-registry")
local pkg      = registry.get_package("csharp-language-server")
if not pkg:is_installed() then
  pkg:install { version = "0.16.0" }
end


-- Setup snippets


local ls = require("luasnip")

vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-J>", function() ls.jump(-1) end, {silent = true})

vim.keymap.set({"i", "s"}, "<C-E>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, {silent = true})

require("luasnip.loaders.from_vscode").lazy_load()

local lspconfig = require("lspconfig")

-- Define a custom function to determine project root using common markers.
local lsp_util = require("lspconfig.util")
local function get_project_root()
  return lsp_util.root_pattern(".git", "package.json", "pyproject.toml", "setup.py")(vim.fn.expand("%:p")) or vim.fn.getcwd()
end

-- Define capabilities using cmp-nvim-lsp
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- nvim-cmp setup
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    format = function(entry, vim_item)
      local icons = {
        Text = "",
        Method = "",
        Function = "󰊕",
        Constructor = "",
        Field = "",
        Variable = "",
        Class = "",
        Interface = "",
        Module = "",
        Property = "",
        Unit = "",
        Value = "",
        Enum = "",
        Keyword = "",
        Snippet = "",
        Color = "",
        File = "",
        Reference = "",
        Folder = "",
        EnumMember = "",
        Constant = "",
        Struct = "פּ",
        Event = "",
        Operator = "",
        TypeParameter = ""
      }
      vim_item.kind = string.format("%s %s", icons[vim_item.kind] or "", vim_item.kind)
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        luasnip = "[Snippet]",
        buffer = "[Buffer]",
        path = "[Path]",
        sql = "[SQL]",
        nvim_lsp_signature_help = "[Signature]",
      })[entry.source.name] or ""
      return vim_item
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, {"i", "s"}),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, {"i", "s"}),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path", option = { get_cwd = get_project_root } },
    { name = "sql" },
    { name = "nvim_lsp_signature_help" }
  })
})

-- Setup command-line (:) completion for NeoVim commands.
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path", option = { get_cwd = get_project_root } }
  }, {
    { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } }
  })
})

-- LSP on_attach function
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- LSP Telescope mappings
  buf_set_keymap('n', 'gd', '<Cmd>Telescope lsp_definitions<CR>', opts)
  buf_set_keymap('n', 'gr', '<Cmd>Telescope lsp_references<CR>', opts)
  buf_set_keymap('n', 'gi', '<Cmd>Telescope lsp_implementations<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<Cmd>Telescope lsp_type_definitions<CR>', opts)
  buf_set_keymap('n', '<leader>ds', '<Cmd>Telescope lsp_document_symbols<CR>', opts)
  buf_set_keymap('n', '<leader>ws', '<Cmd>Telescope lsp_workspace_symbols<CR>', opts)

  -- Other LSP mappings
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<Cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<Cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  --[[ Previous config 
  buf_set_keymap('n', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<C-r>', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  grr gra grn gri i_CTRL-S Some keymaps are created unconditionally when Nvim starts:
  "grn" is mapped in Normal mode to vim.lsp.buf.rename()
  "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
  "grr" is mapped in Normal mode to vim.lsp.buf.references()
  "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
  "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
  CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()
]]

end

-- Set up LSP servers with capabilities
local nvim_lsp = require'lspconfig'
nvim_lsp.clangd.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.eslint.setup {
  on_attach = on_attach,
  capabilities = capabilities,
} 
nvim_lsp.jedi_language_server.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.jsonls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.dockerls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.bashls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.docker_compose_language_service.setup {
  on_attach = on_attach,
  capabilities = capabilities,
} 
nvim_lsp.jdtls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.lua_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = { Lua = {
        completion = { callSnippet = "Replace" },
        diagnostics = { globals = {"vim"} }
    }}
}
nvim_lsp.marksman.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.powershell_es.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.terraformls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

vim.api.nvim_create_autocmd({"BufWritePre"}, {
  pattern = {"*.tf", "*.tfvars"},
  callback = function()
    vim.lsp.buf.format()
  end,
})

nvim_lsp.sqls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.vimls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.bicep.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
nvim_lsp.yamlls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "yaml", "yml" },
    root_dir = function() return vim.loop.cwd() end,
    settings = {
      yaml = {
        validate = true,
        schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
        schemas = { ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = "azure-pipelines.yaml" }
      }
    }
}

nvim_lsp.omnisharp.setup {
    cmd = { "dotnet", vim.fn.expand("~/.local/share/nvim/mason/packages/omnisharp/libexec/OmniSharp.dll") },
    settings = {
      FormattingOptions = {
        EnableEditorConfigSupport = true,
        OrganizeImports = nil,
      },
      MsBuild = {
        LoadProjectsOnDemand = nil,
      },
      RoslynExtensionsOptions = {
        EnableAnalyzersSupport = true,
        EnableImportCompletion = true,
        AnalyzeOpenDocumentsOnly = nil,
      },
      Sdk = {
        IncludePrereleases = true,
      },
    },
    capabilities = capabilities,
}


local pid = vim.fn.getpid()
-- On linux/darwin if using a release build, otherwise under scripts/OmniSharp(.Core)(.cmd)
-- on Windows
-- local omnisharp_bin = "/path/to/omnisharp/OmniSharp.exe"

local csConfig = {
  handlers = {
    ["textDocument/definition"] = require('csharpls_extended').handler,
    ["textDocument/typeDefinition"] = require('csharpls_extended').handler,
  },
  cmd = { "csharp-ls" },
  -- rest of your settings
  capabilities = capabilities,
}

require'lspconfig'.csharp_ls.setup(csConfig)


-- Setup formatters
-- Utilities for creating configurations
local util = require "formatter.util"

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup {
  -- Enable or disable logging
  logging = true,
  -- Set the log level
  log_level = vim.log.levels.WARN,
  -- All formatter configurations are opt-in
  filetype = {
    -- Formatter configurations for filetype "lua" go here
    -- and will be executed in order
    lua = {
        -- "formatter.filetypes.lua" defines default configurations for the
        -- "lua" filetype
        require("formatter.filetypes.lua").stylua,
    }, 
    cs = {
        function()
            return {
                exe = "csharpier",
                args = {
                    "format",
                },
                stdin = true,
            }
        end
    },
    c = {
        require("formatter.filetypes.c").clangformat,
    },
    cmake = {
        require("formatter.filetypes.cmake").cmakelang,
    },
    cpp = {
       require("formatter.filetypes.cpp").clangformat, 
    },
    css = {
       require("formatter.filetypes.css").prettierd, 
    },
    html = {
       require("formatter.filetypes.html").prettierd, 
    },
    java = {
       require("formatter.filetypes.java").clangformat, 
    },
    javascript = {
       require("formatter.filetypes.javascript").prettierd, 
    },
    json = {
       require("formatter.filetypes.json").prettierd, 
    },
    markdown = {
       require("formatter.filetypes.markdown").prettierd, 
    },
    python = {
       require("formatter.filetypes.python").black,
    },
    sh = {
        function()
            local shiftwidth = vim.opt.shiftwidth:get()
            local expandtab = vim.opt.expandtab:get()

            if not expandtab then
                shiftwidth = 0
            end

            return {
                exe = "beautysh",
                args = {
                    "-i",
                    shiftwidth,
                    util.escape_path(util.get_current_buffer_file_path()),
                },
            }
        end
    },
    sql = {
       require("formatter.filetypes.sql").sql_formatter, 
    },
    typescript = {
       require("formatter.filetypes.typescript").prettierd, 
    },
    yaml = {
       require("formatter.filetypes.yaml").prettierd, 
    },
    zsh = {
       require("formatter.filetypes.zsh").beautysh, 
    },
  },
}


-- Auto format on saving
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })
autocmd("BufWritePost", {
	group = "__formatter__",
	command = ":FormatWrite",
})


-- Setup Linting

require('lint').linters_by_ft = {
  markdown = {'vale'},
  cs = {'trivy'},
  terraform = {'tfsec', 'trivy'},
  c = {'trivy'},
  cpp = {'trivy', 'cpplint'},
  cmake = {'cmakelint'},
  html = {'htmlhint'},
  java = {'checkstyle', 'trivy'},
  javascript = {'eslint_d'},
  typescript = {'eslint_d'},
  json = {'jsonlint'},
  python = {'pylint'},
  sh = {'shellcheck'},
  sql = {'sqlfluff'},
  dockerfile = {'trivy'}
}


vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()

    -- try_lint without arguments runs the linters defined in `linters_by_ft`
    -- for the current filetype
    require("lint").try_lint()
  end,
})

-- Setup Debuggers (nvim-dap and nvim-dap-ui)
local dap = require("dap")
local dapui = require("dapui")
dapui.setup()  -- use default settings

-- Automatically open DAP UI when debugging starts, and close it when finished.
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Configure adapter for Python using debugpy
dap.adapters.python = {
  type = 'executable',
  command = 'python',
  args = { '-m', 'debugpy.adapter' },
}
dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = "Launch Python file",
    program = "${file}",
    pythonPath = function() return 'python' end,
  },
}

-- Configure adapter for C# using netcoredbg (assumes installation via Mason)
dap.adapters.coreclr = {
  type = 'executable',
  command = vim.fn.stdpath("data").."/mason/bin/netcoredbg",
  args = {"--interpreter=vscode"}
}
dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch C# project",
    request = "launch",
    program = function()
      return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end,
  },
}

-- Configure adapter for Java using java-debug-adapter
dap.adapters.java = {
  type = 'server',
  host = '127.0.0.1',
  port = 5005,
}
dap.configurations.java = {
  {
    type = 'java',
    request = 'attach',
    name = "Attach to Java process",
    hostName = "127.0.0.1",
    port = 5005,
  },
}


dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = '/home/jacob/.local/share/nvim/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
}


dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = true,
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:1234',
    miDebuggerPath = '/usr/bin/gdb',
    cwd = '${workspaceFolder}',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
  },
}

dap.configurations.c = dap.configurations.cpp



-- Optional key mappings for debugging
vim.api.nvim_set_keymap('n', '<F5>', "<cmd>lua require'dap'.continue()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', "<cmd>lua require'dap'.step_over()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', "<cmd>lua require'dap'.step_into()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', "<cmd>lua require'dap'.step_out()<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>db', "<cmd>lua require'dap'.toggle_breakpoint()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dr', "<cmd>lua require'dap'.repl.open()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>du', "<cmd>lua require'dapui'.toggle()<CR>", { noremap = true, silent = true })


-- Setup persistent-breakpoints
require('persistent-breakpoints').setup{
	load_breakpoints_event = { "BufReadPost" }
}

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
-- Save breakpoints to file automatically.
keymap("n", "<leader>db", "<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>", opts)
keymap("n", "<leader>dc", "<cmd>lua require('persistent-breakpoints.api').set_conditional_breakpoint()<cr>", opts)
keymap("n", "<leader>bc", "<cmd>lua require('persistent-breakpoints.api').clear_all_breakpoints()<cr>", opts)
keymap("n", "<leader>lp", "<cmd>lua require('persistent-breakpoints.api').set_log_point()<cr>", opts)

-- Clipboard integration for WSL/Wayland/X11
if vim.fn.has("wsl") == 1 and not string.find(vim.fn.system('lsb_release -is 2>/dev/null'):lower(), 'ubuntu') then
  -- WSL: Use win32yank.exe to access Windows clipboard
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
elseif (vim.env.XDG_SESSION_TYPE == "wayland" or vim.env.WAYLAND_DISPLAY) and not string.find(vim.fn.system('lsb_release -is 2>/dev/null'):lower(), 'neon') and not vim.fn.has("wsl") == 1 or string.find(vim.fn.system('lsb_release -is 2>/dev/null'):lower(), 'manjarolinux') then
  -- Wayland: use wl-copy/wl-paste
  vim.g.clipboard = {
    name = "wayland",
    copy = {
      ["+"] = "wl-copy",
      ["*"] = "wl-copy",
    },
    paste = {
      ["+"] = "wl-paste",
      ["*"] = "wl-paste",
    },
    cache_enabled = 0,
  }
else  
    -- X11: use xclip as fallback
  vim.g.clipboard = {
    name = "x11",
    copy = {
      ["+"] = "xclip -selection clipboard",
      ["*"] = "xclip -selection primary",
    },
    paste = {
      ["+"] = "xclip -selection clipboard -o",
      ["*"] = "xclip -selection primary -o",
    },
    cache_enabled = 0,
  }
end

-- Gitsigns setup (show git diff in sign column)
require("gitsigns").setup {
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '┃' },
    change       = { text = '┃' },
  },
}

-- Telescope setup (with binary file preview filtering)
local previewers = require("telescope.previewers")
local Job = require("plenary.job")
local new_maker = function(filepath, bufnr, opts)
  filepath = vim.fn.expand(filepath)
  Job:new({
    command = "file", args = { "--mime-type", "-b", filepath },
    on_exit = function(j)
      local mime_type = vim.split(j:result()[1], "/")[1]
      if mime_type == "text" then
        previewers.buffer_previewer_maker(filepath, bufnr, opts)
      else
        vim.schedule(function()
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" })
        end)
      end
    end
  }):sync()
end

require("telescope").setup {
  defaults = {
    buffer_previewer_maker = new_maker,
    preview = {
      -- Display images with `catimg` if the file is an image
      mime_hook = function(filepath, bufnr, opts)
        local function is_image(path)
          local ext = string.match(path:lower(), "%.([^%.]+)$")
          local image_exts = { png=true, jpg=true, jpeg=true }
          return ext and image_exts[ext]
        end
        if is_image(filepath) then
          local term = vim.api.nvim_open_term(bufnr, {})
          vim.fn.jobstart({ "catimg", filepath }, {
            on_stdout = function(_, data)
              for _, d in ipairs(data) do
                vim.api.nvim_chan_send(term, d.."\r\n")
              end
            end,
            stdout_buffered = true, pty = true
          })
        else
          previewers.buffer_previewer_maker(filepath, bufnr, opts)
        end
      end
    }
  }
}
require("telescope").load_extension("csharpls_definition")
-- Rainbow Delimiters (colored brackets) configuration
local rainbow_delimiters = require("rainbow-delimiters")
vim.g.rainbow_delimiters = {
  strategy = {
    ['']  = rainbow_delimiters.strategy["global"],
    vim   = rainbow_delimiters.strategy["local"],
  },
  query = {
    ['']  = 'rainbow-delimiters',
    lua   = 'rainbow-blocks',
  },
  highlight = {
    'RainbowDelimiterRed',
    'RainbowDelimiterYellow',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterGreen',
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan',
  },
}
EOF

" ========== NERDTree Auto-open on Startup =========="
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
let g:NERDTreeShowHidden=1                   " Show hidden files"
let g:NERDTreeIgnore=['^node_modules$']      " Ignore node_modules folders"
let g:NERDTreeFileLines = 1                   " Show number of lines in file"

" ========== Setup Vim-Devicons ============"
" change the default dictionary mappings for file extension matches"
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {} 
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['cs'] = ''
let g:WebDevIconsUnicodeDecorateFileNodesExtensionSymbols['tf'] = ''

let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols = {} 
let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols['.envrc'] = '󰒓'
let g:WebDevIconsUnicodeDecorateFileNodesExactSymbols['azure-pipelines.yaml'] = ''

" ========== Key Mappings =========="
" Terminal mode mapping: allow <Esc> to exit terminal insert mode"
tnoremap <Esc> <C-\><C-n>
" Window navigation with Alt+h/j/k/l (works in terminal if Alt is not trapped)"
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l

nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l

" Remap to handle DA keyboard better

nnoremap ^ }
nnoremap & ^
nnoremap Å {
nnoremap ¤ $

" Telescope fuzzy-finder shortcuts"
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<CR>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<CR>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<CR>


" Require linter"
au BufWritePost * lua require('lint').try_lint()
