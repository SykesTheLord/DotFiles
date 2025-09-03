-- lua/lsp.lua
local on_attach = function(client, bufnr)
    -- LSP keymaps (only active when LSP attaches to current buffer)
    local bufmap = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
    end
    bufmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
    bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
    bufmap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
    bufmap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
    bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    bufmap("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
    bufmap("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
    bufmap("n", "<leader>e", vim.diagnostic.open_float, "Show Diagnostics")
    bufmap("n", "<leader>q", vim.diagnostic.setloclist, "Diagnostics to LocList")
    -- Format on save (if server supports it)
    if client.server_capabilities.documentFormattingProvider then
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ async = false, buffer = bufnr })
            end,
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
local servers = {
    "clangd",
    "ts_ls",
    "lua_ls",
    "eslint",
    "jedi_language_server",
    "jsonls",
    "dockerls",
    "bashls",
    "docker_compose_language_service",
    "jdtls",
    "marksman",
    "powershell_es",
    "terraformls",
    "sqls",
    "vimls",
    "bicep",
    "yamlls",
    "arduino_language_server",
}
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
    settings = { -- example of making the Lua language server recognize Neovim globals
        Lua = {
            diagnostics = { globals = { "vim" } },
        },
    },
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*.tf", "*.tfvars" },
    callback = function()
        vim.lsp.buf.format()
    end,
})

lspconfig.omnisharp.setup({
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
})

lspconfig.yamlls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "yaml", "yml" },
    root_dir = function()
        return vim.loop.cwd()
    end,
    settings = {
        yaml = {
            validate = true,
            schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
            schemas = {
                ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] =
                "azure-pipelines.yaml",
            },
        },
    },
})

local pid = vim.fn.getpid()
-- On linux/darwin if using a release build, otherwise under scripts/OmniSharp(.Core)(.cmd)
-- on Windows
-- local omnisharp_bin = "/path/to/omnisharp/OmniSharp.exe"

local csConfig = {
    handlers = {
        ["textDocument/definition"] = require("csharpls_extended").handler,
        ["textDocument/typeDefinition"] = require("csharpls_extended").handler,
    },
    cmd = { "csharp-ls" },
    -- rest of your settings
    capabilities = capabilities,
}

lspconfig.csharp_ls.setup(csConfig)

-- Rust (using rust-tools for enhanced capabilities)
local rust_tools_ok, rust_tools = pcall(require, "rust-tools")
if rust_tools_ok then
    rust_tools.setup({
        server = { on_attach = on_attach, capabilities = capabilities },
    })
end
