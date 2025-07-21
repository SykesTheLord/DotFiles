local M = {}

function M.setup()
	-- Setup formatters
	-- Utilities for creating configurations
	local util = require("formatter.util")

	-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
	require("formatter").setup({
		-- Enable or disable logging
		logging = true,
		-- Set the log level
		log_level = vim.log.levels.WARN,
		-- All formatter configurations are opt-in
		filetype = {
			lua = {
				require("formatter.filetypes.lua").stylua,
			},
			cs = {
				require("formatter.filetypes.cs").csharpier,
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
				end,
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
	})

	-- Auto format on saving
	local augroup = vim.api.nvim_create_augroup
	local autocmd = vim.api.nvim_create_autocmd
	augroup("__formatter__", { clear = true })
	autocmd("BufWritePost", {
		group = "__formatter__",
		command = ":FormatWrite",
	})
end

return M
