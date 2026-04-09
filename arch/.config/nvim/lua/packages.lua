-- lua/packages.lua
-- Declares all plugins via vim.pack (Neovim 0.12 built-in package manager).
-- Run :lua vim.pack.update() to update all plugins.
-- After first install: run :TSUpdate for treesitter parsers, and
-- cd ~/.local/share/nvim/site/pack/core/opt/markdown-preview.nvim/app && npm install

local plugins = {
    { src = 'https://github.com/AlexvZyl/nordic.nvim' },
    { src = 'https://github.com/folke/snacks.nvim' },
    { src = 'https://github.com/nvim-lua/plenary.nvim' },
    { src = 'https://github.com/MunifTanjim/nui.nvim' },
    { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
    { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim' },
    { src = 'https://github.com/s1n7ax/nvim-window-picker' },
    { src = 'https://github.com/antosha417/nvim-lsp-file-operations' },
    { src = 'https://github.com/williamboman/mason.nvim' },
    { src = 'https://github.com/williamboman/mason-lspconfig.nvim' },
    { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
    { src = 'https://github.com/RaafatTurki/corn.nvim' },
    { src = 'https://github.com/Decodetalkers/csharpls-extended-lsp.nvim' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },
    { src = 'https://github.com/mfussenegger/nvim-dap' },
    { src = 'https://github.com/rcarriga/nvim-dap-ui' },
    { src = 'https://github.com/nvim-neotest/nvim-nio' },
    { src = 'https://github.com/Weissle/persistent-breakpoints.nvim' },
    { src = 'https://github.com/stevearc/conform.nvim' },
    { src = 'https://github.com/mfussenegger/nvim-lint' },
    { src = 'https://github.com/aquasecurity/vim-trivy' },
    { src = 'https://github.com/tpope/vim-fugitive' },
    { src = 'https://github.com/lewis6991/gitsigns.nvim' },
    { src = 'https://github.com/nvim-lualine/lualine.nvim' },
    { src = 'https://github.com/akinsho/bufferline.nvim' },
    { src = 'https://github.com/catgoose/nvim-colorizer.lua' },
    { src = 'https://github.com/iamcco/markdown-preview.nvim' },
    { src = 'https://github.com/windwp/nvim-autopairs' },
    { src = 'https://github.com/jiaoshijie/undotree' },
    { src = 'https://github.com/hiphish/rainbow-delimiters.nvim' },
    { src = 'https://github.com/folke/which-key.nvim' },
}

vim.pack.add(plugins)

-- All plugins go to opt/; load them all eagerly at startup.
for _, p in ipairs(plugins) do
    local name = p.name or vim.fs.basename(p.src)
    pcall(vim.cmd.packadd, name)
end
