local M = {}

function M.setup()
	require("lint").linters_by_ft = {
		markdown = { "vale" },
		cs = { "trivy" },
		terraform = { "tfsec", "trivy" },
		c = { "trivy" },
		cpp = { "trivy", "cpplint" },
		cmake = { "cmakelint" },
		html = { "htmlhint" },
		java = { "checkstyle", "trivy" },
		javascript = { "eslint_d" },
		typescript = { "eslint_d" },
		json = { "jsonlint" },
		python = { "pylint" },
		sh = { "shellcheck" },
		sql = { "sqlfluff" },
		dockerfile = { "trivy" },
	}

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function()
			-- try_lint without arguments runs the linters defined in `linters_by_ft`
			-- for the current filetype
			require("lint").try_lint()
		end,
	})
end

return M
