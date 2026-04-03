-- lua/keymaps.lua
local map = vim.keymap.set

-- Normal mode leader mappings
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "File Explorer (Neo-tree)" })
map("n", "<leader>o", ":Neotree reveal<CR>", { desc = "Reveal current file in Neo-tree" })

-- Convenience mappings
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>fh", function()
	Snacks.picker.help()
end, { desc = "Search Help" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file (CTRL+S)" })

-- Window navigation (using Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to split below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to split above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
