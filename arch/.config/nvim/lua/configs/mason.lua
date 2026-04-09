-- lua/configs/mason.lua
require("mason").setup()

require("mason-tool-installer").setup({
    ensure_installed = {
        "trivy",               -- Linter for various issues
        "csharpier",           -- C# formatter
        "netcoredbg",          -- C# debugger
        "black",               -- Python formatter
        "debugpy",             -- Python debugger
        "pylint",              -- Python linter
        "eslint_d",            -- JS/TS linter
        "jsonlint",            -- JSON linter
        "beautysh",            -- Shell formatter
        "shellcheck",          -- Shell linter
        "prettierd",           -- Formatter for web languages
        "java-debug-adapter",  -- Java debugger
        "clang-format",        -- C/C++ formatter
        "stylua",              -- Lua formatter
        "luacheck",            -- Lua linter
        "cmakelang",           -- CMake formatter/linter
        "sqlfluff",            -- SQL linter
        "sql-formatter",       -- SQL formatter
        "vale",                -- Markdown linter
        "tfsec",               -- Terraform linter
        "cpplint",             -- C++ linter
        "cmakelint",           -- CMake linter
        "htmlhint",            -- HTML linter
        "checkstyle",          -- Java linter
        "cpptools",            -- C/C++/Rust debugger
        "google-java-format",  -- Java formatter
    },
    automatic_installation = true,
    auto_update = true,
})

require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd",
        "eslint",
        "jedi_language_server",
        "jsonls",
        "yamlls",
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
    automatic_enable = false,
})

-- Ensure specific version of C# LSP (csharp_ls)
local registry = require("mason-registry")
local pkg = registry.get_package("csharp-language-server")
if not pkg:is_installed() then
    pkg:install({ version = "0.16.0" })
end
