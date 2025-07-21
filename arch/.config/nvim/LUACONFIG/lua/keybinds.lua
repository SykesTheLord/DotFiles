local M = {}

function M.setup()
	local keymap = vim.keymap.set
	keymap("n", "<leader>rn", function()
		vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
			callback = function()
				local key = vim.api.nvim_replace_termcodes("<C-f>", true, false, true)
				vim.api.nvim_feedkeys(key, "c", false)
				vim.api.nvim_feedkeys("0", "n", false)
				return true
			end,
		})
		vim.lsp.buf.rename()
	end)
	-- Terminal mode: allow <Esc> to exit terminal insert mode.
	keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })

	-- Window navigation with Alt+h/j/k/l in insert mode.
	keymap("i", "<A-h>", "<C-\\><C-N><C-w>h", { noremap = true, silent = true })
	keymap("i", "<A-j>", "<C-\\><C-N><C-w>j", { noremap = true, silent = true })
	keymap("i", "<A-k>", "<C-\\><C-N><C-w>k", { noremap = true, silent = true })
	keymap("i", "<A-l>", "<C-\\><C-N><C-w>l", { noremap = true, silent = true })

	-- Window navigation with Alt+h/j/k/l in normal mode.
	keymap("n", "<A-h>", "<C-w>h", { noremap = true, silent = true })
	keymap("n", "<A-j>", "<C-w>j", { noremap = true, silent = true })
	keymap("n", "<A-k>", "<C-w>k", { noremap = true, silent = true })
	keymap("n", "<A-l>", "<C-w>l", { noremap = true, silent = true })

	-- Telescope fuzzy-finder shortcuts in normal mode.
	keymap("n", "<leader>ff", function()
		require("telescope.builtin").find_files()
	end, { noremap = true, silent = true })
	keymap("n", "<leader>fg", function()
		require("telescope.builtin").live_grep()
	end, { noremap = true, silent = true })
	keymap("n", "<leader>fb", function()
		require("telescope.builtin").buffers()
	end, { noremap = true, silent = true })
	keymap("n", "<leader>fh", function()
		require("telescope.builtin").help_tags()
	end, { noremap = true, silent = true })
end

return M
