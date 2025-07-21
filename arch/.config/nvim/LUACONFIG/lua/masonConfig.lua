-- lua/mason_setup.lua
local M = {}

function M.setup()
	-- Mason Package Manager setup.
	require("mason").setup()

	-- Mason-Tool-Installer setup.
	require("mason-tool-installer").setup({
		ensure_installed = {
			"trivy", -- Linter for various issues.
			"csharpier", -- C# formatter.
			"netcoredbg", -- C# debugger.
			"black", -- Python formatter.
			"debugpy", -- Python debugger.
			"pylint", -- Python linter.
			"eslint_d", -- JavaScript and TypeScript linter.
			"jsonlint", -- JSON linter.
			"beautysh", -- Bash, Csh, Zsh formatter.
			"shellcheck", -- Bash linter.
			"prettierd", -- Formatter for Angular, CSS, Flow, GraphQL, HTML, JSON, JSX, JavaScript, LESS, Markdown, SCSS, TypeScript, Vue, YAML.
			"java-debug-adapter", -- Java debugger.
			"clang-format", -- Formatter for C, C++, JSON, Java, and JavaScript.
			"stylua", -- Lua formatter.
			"luacheck", -- Lua linter.
			"cmakelang", -- CMake formatter and linter.
			"sqlfluff", -- SQL linter.
			"sql-formatter", -- SQL formatter.
			"vale", -- Markdown linter.
			"tfsec", -- Terraform linter.
			"cpplint", -- C++ linter.
			"cmakelint", -- CMake linter.
			"htmlhint", -- HTML linter.
			"checkstyle", -- Java linter.
			"cpptools", -- C, C++ and Rust debugger.
		},
		automatic_installation = true,
		auto_update = true,
	})

	-- Mason-LSPconfig integration (automatic LSP installation).
	require("mason-lspconfig").setup({
		ensure_installed = {
			"clangd",
			"eslint",
			"jedi_language_server",
			"jsonls",
			"yamlls",
			-- "omnisharp",  -- (Handled separately below)
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
			"csharp_ls",
		},
		automatic_installation = true,
		auto_update = true,
	})
end

return M
