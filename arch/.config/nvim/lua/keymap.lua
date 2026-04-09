-- lua/keymap.lua
local map = vim.keymap.set

-- File explorer
map("n", "<leader>e", ":Neotree toggle<CR>", { desc = "File Explorer (Neo-tree)" })
map("n", "<leader>o", ":Neotree reveal<CR>",  { desc = "Reveal current file in Neo-tree" })

-- Convenience mappings
map("n", "<leader>w", "<cmd>w<CR>",  { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>",  { desc = "Quit" })
map("n", "<C-s>",     "<cmd>w<CR>",  { desc = "Save file (CTRL+S)" })

-- Window navigation (Ctrl + hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to split below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to split above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Undotree
map("n", "<leader>u",  require("undotree").toggle, { noremap = true, silent = true })
map("n", "<leader>uo", require("undotree").open,   { noremap = true, silent = true })
map("n", "<leader>uc", require("undotree").close,  { noremap = true, silent = true })

-- Snippet navigation (vim.snippet, replaces LuaSnip Tab/S-Tab)
map({ 'i', 's' }, '<Tab>', function()
    if vim.snippet.active({ direction = 1 }) then
        return '<Cmd>lua vim.snippet.jump(1)<CR>'
    end
    return '<Tab>'
end, { expr = true, desc = "Snippet: jump forward or Tab" })

map({ 'i', 's' }, '<S-Tab>', function()
    if vim.snippet.active({ direction = -1 }) then
        return '<Cmd>lua vim.snippet.jump(-1)<CR>'
    end
    return '<S-Tab>'
end, { expr = true, desc = "Snippet: jump back or S-Tab" })

-- Confirm completion item with Enter (built-in completion)
map('i', '<CR>', function()
    return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true, desc = "Confirm completion or newline" })
