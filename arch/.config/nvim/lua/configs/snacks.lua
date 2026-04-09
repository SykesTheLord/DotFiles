-- lua/configs/snacks.lua
-- Snacks.nvim setup: opts + all keybindings (converted from lazy.nvim keys table).
-- The VeryLazy autocmd from the lazy spec is replaced with direct calls here.

require('snacks').setup({
    bigfile    = { enabled = true },
    explorer   = { enabled = true },
    indent     = { enabled = true },
    input      = { enabled = true },
    notifier   = { enabled = true, timeout = 8000 },
    picker     = { enabled = true },
    quickfile  = { enabled = true },
    scope      = { enabled = true },
    scroll     = { enabled = false },
    statuscolumn = { enabled = true },
    words      = { enabled = true },
    styles = {
        notification = {},
    },
})

-- Debug globals (was in the VeryLazy autocmd init block)
_G.dd = function(...) Snacks.debug.inspect(...) end
_G.bt = function() Snacks.debug.backtrace() end
vim.print = _G.dd

-- UI toggles
Snacks.toggle.option("spell",        { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap",         { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.option("conceallevel", {
    off = 0,
    on  = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
}):map("<leader>uc")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.dim():map("<leader>uD")

-- Helper: register a normal-mode keymap
local function map(lhs, fn, desc)
    vim.keymap.set('n', lhs, fn, { desc = desc })
end
local function mapv(lhs, fn, desc)
    vim.keymap.set({ 'n', 'v' }, lhs, fn, { desc = desc })
end
local function mapt(lhs, fn, desc)
    vim.keymap.set({ 'n', 't' }, lhs, fn, { desc = desc })
end
local function mapx(lhs, fn, desc)
    vim.keymap.set({ 'n', 'x' }, lhs, fn, { desc = desc })
end

-- Top pickers & explorer -------------------------------------------------------
map("<leader><space>", function() Snacks.picker.smart() end,             "Smart Find Files")
map("<leader>,",       function() Snacks.picker.buffers() end,           "Buffers")
map("<leader>/",       function() Snacks.picker.grep() end,              "Grep")
map("<leader>:",       function() Snacks.picker.command_history() end,   "Command History")
map("<leader>n",       function() Snacks.picker.notifications() end,     "Notification History")
map("<leader>fc",      function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, "Find Config File")
map("<leader>ff",      function() Snacks.picker.files() end,             "Find Files")
map("<leader>fg",      function() Snacks.picker.grep() end,              "Grep Files")
map("<leader>fp",      function() Snacks.picker.projects() end,          "Projects")
map("<leader>fr",      function() Snacks.picker.recent() end,            "Recent")
map("<leader>fb",      function() Snacks.picker.buffers() end,           "Buffers")

-- Git --------------------------------------------------------------------------
map("<leader>gb",  function() Snacks.picker.git_branches() end,  "Git Branches")
map("<leader>gl",  function() Snacks.picker.git_log() end,       "Git Log")
map("<leader>gL",  function() Snacks.picker.git_log_line() end,  "Git Log Line")
map("<leader>gs",  function() Snacks.picker.git_status() end,    "Git Status")
map("<leader>gS",  function() Snacks.picker.git_stash() end,     "Git Stash")
map("<leader>gd",  function() Snacks.picker.git_diff() end,      "Git Diff (Hunks)")
map("<leader>gf",  function() Snacks.picker.git_log_file() end,  "Git Log File")
mapv("<leader>gB", function() Snacks.gitbrowse() end,            "Git Browse")

-- Grep / Search ----------------------------------------------------------------
map("<leader>sb",  function() Snacks.picker.lines() end,         "Buffer Lines")
map("<leader>sB",  function() Snacks.picker.grep_buffers() end,  "Grep Open Buffers")
map("<leader>sg",  function() Snacks.picker.grep() end,          "Grep")
mapx("<leader>sw", function() Snacks.picker.grep_word() end,     "Visual selection/word")

-- Misc search helpers ----------------------------------------------------------
map('<leader>s"', function() Snacks.picker.registers() end,      "Registers")
map("<leader>s/", function() Snacks.picker.search_history() end, "Search History")
map("<leader>sa", function() Snacks.picker.autocmds() end,       "Autocmds")
map("<leader>sc", function() Snacks.picker.command_history() end,"Command History")
map("<leader>sC", function() Snacks.picker.commands() end,       "Commands")
map("<leader>sd", function() Snacks.picker.diagnostics() end,    "Diagnostics")
map("<leader>sD", function() Snacks.picker.diagnostics_buffer() end, "Buffer Diagnostics")
map("<leader>sh", function() Snacks.picker.help() end,           "Help Pages")
map("<leader>sH", function() Snacks.picker.highlights() end,     "Highlights")
map("<leader>si", function() Snacks.picker.icons() end,          "Icons")
map("<leader>sj", function() Snacks.picker.jumps() end,          "Jumps")
map("<leader>sk", function() Snacks.picker.keymaps() end,        "Keymaps")
map("<leader>sl", function() Snacks.picker.loclist() end,        "Location List")
map("<leader>sm", function() Snacks.picker.marks() end,          "Marks")
map("<leader>sM", function() Snacks.picker.man() end,            "Man Pages")
map("<leader>sq", function() Snacks.picker.qflist() end,         "Quickfix List")
map("<leader>sR", function() Snacks.picker.resume() end,         "Resume")
map("<leader>su", function() Snacks.picker.undo() end,           "Undo History")

-- Colourschemes ----------------------------------------------------------------
map("<leader>uC", function() Snacks.picker.colorschemes() end,   "Colourschemes")

-- LSP --------------------------------------------------------------------------
map("gd",          function() Snacks.picker.lsp_definitions() end,        "Goto Definition")
map("gD",          function() Snacks.picker.lsp_declarations() end,       "Goto Declaration")
vim.keymap.set('n', "gr", function() Snacks.picker.lsp_references() end,  { desc = "References", nowait = true })
map("gI",          function() Snacks.picker.lsp_implementations() end,    "Goto Implementation")
map("gy",          function() Snacks.picker.lsp_type_definitions() end,   "Goto Type Definition")
map("<leader>ss",  function() Snacks.picker.lsp_symbols() end,            "LSP Symbols")
map("<leader>sS",  function() Snacks.picker.lsp_workspace_symbols() end,  "Workspace Symbols")

-- Miscellaneous ----------------------------------------------------------------
map("<leader>z",  function() Snacks.zen() end,           "Toggle Zen Mode")
map("<leader>Z",  function() Snacks.zen.zoom() end,      "Toggle Zoom")
map("<leader>.",  function() Snacks.scratch() end,       "Toggle Scratch Buffer")
map("<leader>S",  function() Snacks.scratch.select() end,"Select Scratch Buffer")
map("<leader>bd", function() Snacks.bufdelete() end,     "Delete Buffer")
map("<leader>cR", function() Snacks.rename.rename_file() end, "Rename File")
map("<leader>un", function() Snacks.notifier.hide() end, "Dismiss All Notifications")

-- Terminal ---------------------------------------------------------------------
vim.keymap.set('n', "<c-/>", function() Snacks.terminal() end, { desc = "Toggle Terminal" })
vim.keymap.set('n', "<c-_>", function() Snacks.terminal() end, { desc = "which_key_ignore" })

-- Word motions (also active in terminal mode) ----------------------------------
mapt("]]", function() Snacks.words.jump(vim.v.count1) end,  "Next Reference")
mapt("[[", function() Snacks.words.jump(-vim.v.count1) end, "Prev Reference")

-- Neovim NEWS window -----------------------------------------------------------
map("<leader>N", function()
    Snacks.win({
        file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
        width = 0.6,
        height = 0.6,
        wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
        },
    })
end, "Neovim News")
