-- lua/ui.lua
-- (If needed, additional UI config could go here. In this config, most UI plugins
-- are configured directly in their lazy.nvim spec entries.)
-- Example: ensure the colorscheme is set (if not already done in plugin config)
vim.cmd.colorscheme("nordic")
vim.opt.termguicolors = true
require("bufferline").setup({})
vim.cmd("Neotree reveal left")
