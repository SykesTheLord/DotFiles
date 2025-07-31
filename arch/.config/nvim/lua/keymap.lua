-- lua/keymaps.lua
local map = vim.keymap.set
-- Normal mode leader mappings
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "File Explorer (Neo-tree)" })
map("n", "<leader>o", ":Neotree reveal<CR>", { desc = "Reveal current file in Neo-tree" })
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find Files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Live Grep" })
map("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "List Buffers" })
map("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Search Help" })
-- Convenience mappings
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file (CTRL+S)" })
-- Window navigation (using Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to split below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to split above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
map("n", "<leader>u", require("undotree").toggle, { noremap = true, silent = true })
map("n", "<leader>uo", require("undotree").open, { noremap = true, silent = true })
map("n", "<leader>uc", require("undotree").close, { noremap = true, silent = true })
