-- cmp and common configuration remain unchanged.
local lspconfig = require("lspconfig")
local lsp_util = require("lspconfig.util")
local cmp = require("cmp")
local luasnip = require("luasnip")

-- Define a custom function to determine the project root using common markers.
local function get_project_root()
	return lsp_util.root_pattern(".git", "package.json", "pyproject.toml", "setup.py")(vim.fn.expand("%:p"))
		or vim.fn.getcwd()
end

-- Define capabilities using cmp-nvim-lsp.
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- nvim-cmp setup.
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
				TypeParameter = "",
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
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "buffer" },
		{ name = "path", option = { get_cwd = get_project_root } },
		{ name = "sql" },
		{ name = "nvim_lsp_signature_help" },
	}),
})

-- Setup command-line (:) completion for NeoVim commands.
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path", option = { get_cwd = get_project_root } },
	}, {
		{ name = "cmdline", option = { ignore_cmds = { "Man", "!" } } },
	}),
})

-- Define the common LSP on_attach function.
local on_attach = function(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	local function buf_set_option(...)
		vim.api.nvim_buf_set_option(bufnr, ...)
	end

	-- Enable completion triggered by <c-x><c-o>
	buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

	-- Mappings.
	local opts = { noremap = true, silent = true }
	-- LSP Telescope mappings.
	buf_set_keymap("n", "gd", "<Cmd>Telescope lsp_definitions<CR>", opts)
	buf_set_keymap("n", "gr", "<Cmd>Telescope lsp_references<CR>", opts)
	buf_set_keymap("n", "gi", "<Cmd>Telescope lsp_implementations<CR>", opts)
	buf_set_keymap("n", "<leader>D", "<Cmd>Telescope lsp_type_definitions<CR>", opts)
	buf_set_keymap("n", "<leader>ds", "<Cmd>Telescope lsp_document_symbols<CR>", opts)
	buf_set_keymap("n", "<leader>ws", "<Cmd>Telescope lsp_workspace_symbols<CR>", opts)
	-- Other LSP mappings.
	buf_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
	buf_set_keymap("n", "<leader>e", "<Cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
	buf_set_keymap("n", "[d", "<Cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
	buf_set_keymap("n", "]d", "<Cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
	buf_set_keymap("n", "<space>q", "<Cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
	-- Additional keymaps from previous config (commented out for clarity).
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

--------------------------------------------------------------------------------
-- LSP Setup Functions
--
-- Each function below accepts 'on_attach' and 'capabilities' as parameters.
--------------------------------------------------------------------------------
local M = {}

function M.setup_clangd(on_attach, capabilities)
	lspconfig.clangd.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_eslint(on_attach, capabilities)
	lspconfig.eslint.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_jedi_language_server(on_attach, capabilities)
	lspconfig.jedi_language_server.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_jsonls(on_attach, capabilities)
	lspconfig.jsonls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_dockerls(on_attach, capabilities)
	lspconfig.dockerls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_bashls(on_attach, capabilities)
	lspconfig.bashls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_docker_compose_language_service(on_attach, capabilities)
	lspconfig.docker_compose_language_service.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_jdtls(on_attach, capabilities)
	lspconfig.jdtls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_lua_ls(on_attach, capabilities)
	lspconfig.lua_ls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
		settings = {
			Lua = {
				completion = { callSnippet = "Replace" },
				diagnostics = { globals = { "vim" } },
			},
		},
	})
end

function M.setup_marksman(on_attach, capabilities)
	lspconfig.marksman.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_powershell_es(on_attach, capabilities)
	lspconfig.powershell_es.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_terraformls(on_attach, capabilities)
	lspconfig.terraformls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
	-- Autocommand for formatting Terraform files.
	vim.api.nvim_create_autocmd({ "BufWritePre" }, {
		pattern = { "*.tf", "*.tfvars" },
		callback = function()
			vim.lsp.buf.format()
		end,
	})
end

function M.setup_sqls(on_attach, capabilities)
	lspconfig.sqls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_vimls(on_attach, capabilities)
	lspconfig.vimls.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_bicep(on_attach, capabilities)
	lspconfig.bicep.setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_yamlls(on_attach, capabilities)
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
					["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = "azure-pipelines.yaml",
				},
			},
		},
	})
end

function M.setup_omnisharp(on_attach, capabilities)
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
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

function M.setup_csharp_ls(on_attach, capabilities)
	local csConfig = {
		handlers = {
			["textDocument/definition"] = require("csharpls_extended").handler,
			["textDocument/typeDefinition"] = require("csharpls_extended").handler,
		},
		cmd = { "csharp-ls" },
		on_attach = on_attach,
		capabilities = capabilities,
	}
	lspconfig.csharp_ls.setup(csConfig)
end

--------------------------------------------------------------------------------
-- End of LSP Setup Functions.
--------------------------------------------------------------------------------

-- Return the module so that other parts of your config can call these functions.
return {
	on_attach = on_attach,
	capabilities = capabilities,
	lsp_setup = M,
	get_project_root = get_project_root,
}
