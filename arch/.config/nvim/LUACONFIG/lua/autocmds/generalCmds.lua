local M = {}

function M.setup()
	-- NERDTree Auto-open on Startup
	vim.api.nvim_create_autocmd("StdinReadPre", {
		callback = function()
			-- Set a flag (using a global variable) to indicate input is coming from stdin.
			vim.g.std_in = true
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			-- If no file arguments were given and we did not detect stdin input, open NERDTree.
			if vim.fn.argc() == 0 and not vim.g.std_in then
				vim.cmd("NERDTree")
			end
		end,
	})
end

return M
