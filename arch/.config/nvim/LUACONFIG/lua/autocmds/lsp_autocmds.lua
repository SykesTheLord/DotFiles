local M = {}

function M.setup()
	-- CMake: force filetype for CMakeLists.txt and *.cmake files
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		pattern = { "CMakeLists.txt", "*.cmake" },
		callback = function()
			vim.bo.filetype = "cmake"
		end,
	})

	-- Docker Compose: force filetype if the filename matches
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		pattern = { "docker-compose.yml", "docker-compose.yaml" },
		callback = function()
			vim.bo.filetype = "dockercompose"
		end,
	})

	-- PowerShell: force filetype for *.ps1 files
	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		pattern = "*.ps1",
		callback = function()
			vim.bo.filetype = "powershell"
		end,
	})

	-- Autocomplete for terminal buffers: always set completeopt for TermOpen
	vim.api.nvim_create_autocmd("TermOpen", {
		pattern = "*",
		callback = function()
			vim.cmd("setlocal completeopt=menu,menuone,noselect")
		end,
	})

	-- LSP autocommands using early events (BufReadPost & BufNewFile)

	-- C and C++ (using clangd)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = { "c", "cpp" },
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_clangd(lsp.on_attach, lsp.capabilities)
			local debug = require("debugging")
			debug.setup_cpp()
		end,
	})

	-- JavaScript / TypeScript (using eslint)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_eslint(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Python (using jedi_language_server)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "python",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_jedi_language_server(lsp.on_attach, lsp.capabilities)
			local debug = require("debugging")
			debug.setup_python()
		end,
	})

	-- JSON (using jsonls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "json",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_jsonls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Dockerfile (using dockerls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "dockerfile",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_dockerls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Docker Compose (using docker_compose_language_service)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "dockercompose",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_docker_compose_language_service(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Bash (using bashls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = { "sh", "bash" },
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_bashls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Java (using jdtls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "java",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_jdtls(lsp.on_attach, lsp.capabilities)
			local debug = require("debugging")
			debug.setup_java()
		end,
	})

	-- Lua (using lua_ls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "*.lua",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_lua_ls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Markdown (using marksman)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "markdown",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_marksman(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- PowerShell (using powershell_es)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "powershell",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_powershell_es(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Terraform (using terraformls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = { "terraform", "tf", "tfvars" },
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_terraformls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- SQL (using sqls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "sql",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_sqls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- Vimscript (using vimls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "vim",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_vimls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- YAML (using yamlls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = { "yaml", "yml" },
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_yamlls(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- C# (using omnisharp and csharp_ls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "cs",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_omnisharp(lsp.on_attach, lsp.capabilities)
			lsp.lsp_setup.setup_csharp_ls(lsp.on_attach, lsp.capabilities)
			local debug = require("debugging")
			debug.setup_cs()
		end,
	})

	-- Bicep (using bicep)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "bicep",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_bicep(lsp.on_attach, lsp.capabilities)
		end,
	})

	-- CMake (using cmake_ls)
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "cmake",
		callback = function()
			local lsp = require("lsp")
			lsp.lsp_setup.setup_cmake_ls(lsp.on_attach, lsp.capabilities)
		end,
	})
end

return M
