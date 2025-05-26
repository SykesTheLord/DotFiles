# Neovim Shortcuts Documentation

This document provides an overview of custom key bindings defined in the [init.vim](https://raw.githubusercontent.com/SykesTheLord/NeoVimConfig/refs/heads/main/init.vim) configuration as well as general Vim/Neovim key mappings categorized by mode. For additional background on Vim/Nvim mappings, refer to the [vim.rtorr.com cheat sheet](https://vim.rtorr.com/) :contentReference[oaicite:1]{index=1} and the [Neovim docs on mapping keys](https://neovim.io/doc/user/map.html) :contentReference[oaicite:2]{index=2}.

---

## Table of Contents

- [Basic Settings](#basic-settings)
- [General Vim/Neovim Key Mappings](#general-vimnvim-key-mappings)
  - [Normal Mode](#normal-mode)
  - [Insert Mode](#insert-mode)
  - [Visual Mode](#visual-mode)
  - [Command-Line Mode](#command-line-mode)
- [LSP Shortcuts](#lsp-shortcuts)
- [Telescope Shortcuts](#telescope-shortcuts)
- [Snippet Navigation Shortcuts](#snippet-navigation-shortcuts)
- [Window Navigation Shortcuts](#window-navigation-shortcuts)
- [DA Keyboard Remappings](#da-keyboard-remappings)
- [Debugger Shortcuts](#debugger-shortcuts)
- [Persistent Breakpoints Shortcuts](#persistent-breakpoints-shortcuts)
- [Terminal Mode Shortcut](#terminal-mode-shortcut)
- [Linting on Save](#linting-on-save)
- [Further Reading](#further-reading)

---

## Basic Settings

Several basic Neovim settings are configured in the file (line numbering, mouse support, tab settings, system clipboard, etc.). Although these aren’t key mappings per se, they set the stage for a streamlined editing experience.

---

## General Vim/Neovim Key Mappings

This section summarizes common Vim key bindings, organized by mode. These are the basic shortcuts you can use in any Vim or Neovim setup.

### Normal Mode

- **Navigation:**

  - `h`, `j`, `k`, `l`  
    _Move left, down, up, and right respectively._
  - `w` / `b`  
    _Jump forward/backward by word._
  - `0` / `¤`  
    _Jump to the beginning or end of a line._
  - `gg` / `G`  
    _Jump to the first/last line of the file._
  - `Å` / `^`
    _Jump to the previous/next paragraph._
  - `&`
    _Jump to the next non-blank character._

- **Editing & Text Operations:**

  - `dd`  
    _Delete the current line._
  - `yy`  
    _Yank (copy) the current line._
  - `p`  
    _Paste after the cursor._
  - `x`  
    _Delete the character under the cursor._
  - `dw`  
    _Delete from the cursor to the start of the next word._
  - `cw` / `ciw`  
    _Change a word or the inner word._
  - `u` / `CTRL-R`  
    _Undo / Redo changes._

- **Searching & Substitution:**
  - `/pattern` / `?pattern`  
    _Search forward/backward for a pattern._
  - `n` / `N`  
    _Repeat the search in the same/opposite direction._
  - `:%s/old/new/g`  
    _Perform a global substitution within the file._

### Insert Mode

- **Entering Text:**

  - `i`  
    _Insert before the cursor._
  - `I`  
    _Insert at the beginning of the current line._
  - `a`  
    _Append after the cursor._
  - `A`  
    _Append at the end of the current line._
  - `o`  
    _Open a new line below and enter Insert mode._
  - `O`  
    _Open a new line above and enter Insert mode._

- **Exiting:**
  - `Esc`  
    _Exit Insert mode and return to Normal mode._

### Visual Mode

- **Selection:**

  - `v`  
    _Enter visual mode (character-wise selection)._
  - `V`  
    _Enter visual line mode (line-wise selection)._
  - `CTRL-V`  
    _Enter visual block mode._

- **Editing Selected Text:**
  - `y`  
    _Yank (copy) the selected text._
  - `d`  
    _Delete the selected text._
  - `c`  
    _Change the selected text (delete and enter Insert mode)._

### Command-Line Mode

- **Command Execution:**
  - `:`  
    _Enter Command-line mode to execute Ex commands (e.g., saving `:w`, quitting `:q`)._

_For more detailed key mappings and usage, visit [vim.rtorr.com](https://vim.rtorr.com/) :contentReference[oaicite:3]{index=3}._

---

## LSP Shortcuts

When an LSP server attaches to a buffer, the following Normal mode key mappings are configured:

- **`gd`**  
  _Action:_ Opens Telescope’s definition finder (`Telescope lsp_definitions`).  
  _Description:_ Jumps to the definition of the symbol under the cursor.

- **`gr`**  
  _Action:_ Opens Telescope’s reference finder (`Telescope lsp_references`).  
  _Description:_ Lists all references for the symbol.

- **`gi`**  
  _Action:_ Opens Telescope’s implementation finder (`Telescope lsp_implementations`).  
  _Description:_ Jumps to the implementation of the symbol.

- **`D`**  
  _Action:_ Opens Telescope’s type definitions finder (`Telescope lsp_type_definitions`).  
  _Description:_ Jumps to the type definition of the symbol.

- **`ds`**  
  _Action:_ Opens Telescope’s document symbols (`Telescope lsp_document_symbols`).  
  _Description:_ Lists symbols in the current file.

- **`ws`**  
  _Action:_ Opens Telescope’s workspace symbols (`Telescope lsp_workspace_symbols`).  
  _Description:_ Searches for symbols across the workspace.

- **`K`**  
  _Action:_ Triggers LSP hover (`vim.lsp.buf.hover()`).  
  _Description:_ Displays documentation or type information about the symbol.

- **`e`**  
  _Action:_ Shows diagnostics for the current line (`vim.lsp.diagnostic.show_line_diagnostics()`).  
  _Description:_ Provides error and warning messages.

- **`[d`** and **`]d`**  
  _Actions:_ Navigate to previous (`vim.lsp.diagnostic.goto_prev()`) and next (`vim.lsp.diagnostic.goto_next()`) diagnostics.

- **`q`**  
  _Action:_ Populates the location list with diagnostics (`vim.lsp.diagnostic.set_loclist()`).  
  _Description:_ Prepares diagnostics for an overview and quick navigation.

---

## Telescope Shortcuts

Telescope, the fuzzy finder, is bound to the following Normal mode shortcuts:

- **`-ff`**  
  _Action:_ Opens the file finder (`telescope.builtin.find_files()`).  
  _Description:_ Search and open files.

- **`-fg`**  
  _Action:_ Launches live grep (`telescope.builtin.live_grep()`).  
  _Description:_ Search text across files.

- **`-fb`**  
  _Action:_ Lists open buffers (`telescope.builtin.buffers()`).  
  _Description:_ Switch between open buffers.

- **`-fh`**  
  _Action:_ Displays help tags (`telescope.builtin.help_tags()`).  
  _Description:_ Access Vim’s help documentation.

---

## Snippet Navigation Shortcuts

Using LuaSnip for snippet management, these shortcuts (configured for Insert and Select modes) enable efficient snippet navigation:

- **`<C-k>`**  
  _Action:_ Jump to the next snippet placeholder.

- **`<C-j>`**  
  _Action:_ Jump to the previous snippet placeholder.

- **`<C-l>`**  
  _Action:_ Cycle through available snippet choices (if a choice list is active).

_Note: These key strings are defined using `vim.keymap.set` in the configuration and can be adjusted based on personal preference._

---

## Window Navigation Shortcuts

Enhance split window navigation without needing to rely solely on `<C-w>` commands:

- **`<A-h>`**  
  _Action:_ Move to the left split window.

- **`<A-j>`**  
  _Action:_ Move to the split below.

- **`<A-k>`**  
  _Action:_ Move to the split above.

- **`<A-l>`**  
  _Action:_ Move to the right split window.

---

## DA Keyboard Remappings

Adjustments for the Danish keyboard layout include the following remappings:

- **`^`**  
  _Remapped to:_ `}`  
  _Description:_ Jump to the next paragraph.

- **`&`**  
  _Remapped to:_ `^`  
  _Description:_ Facilitate easier navigation.

- **`Å`**  
  _Remapped to:_ `{`  
  _Description:_ Jump to the previous paragraph.

---

## Debugger Shortcuts

The configuration integrates debugging support via [nvim-dap](https://github.com/mfussenegger/nvim-dap). Key debugger actions—such as continue, step over, step into, and step out—are defined using `vim.api.nvim_set_keymap`. Customize these mappings further as needed.

- **`<F5>`**
  _Action:_ Continue debugging.
  _Command:_ `lua require'dap'.continue()`

- **`<F10>`**
  _Action:_ Step over the next function call.
  _Command:_ `lua require'dap'.step_over()`

- **`<F11>`**
  _Action:_ Step into the next function call.
  _Command:_ `lua require'dap'.step_into()`

- **`<F12>`**
  _Action:_ Step out of the current function.
  _Command:_ `lua require'dap'.step_out()`

- **`<leader>dr`**
  _Action:_ Open REPL UI.
  _Command:_ `lua require'dap'.repl.open()`

- **`<leader>du`**
  _Action:_ Open debugger UI.
  _Command:_ `lua require'dapui'.toggle()`

---

## Persistent Breakpoints Shortcuts

For managing breakpoints persistently, the following Normal mode mappings are provided:

- **`db`**  
  _Action:_ Toggle a breakpoint at the current line.  
  _Command:_ `lua require('persistent-breakpoints.api').toggle_breakpoint()`

- **`dc`**  
  _Action:_ Set a conditional breakpoint.  
  _Command:_ `lua require('persistent-breakpoints.api').set_conditional_breakpoint()`

- **`bc`**  
  _Action:_ Clear all breakpoints.  
  _Command:_ `lua require('persistent-breakpoints.api').clear_all_breakpoints()`

- **`lp`**  
  _Action:_ Set a log point.  
  _Command:_ `lua require('persistent-breakpoints.api').set_log_point()`

---

## Terminal Mode Shortcut

- **`<C-\><C-n>`**  
  _Action:_ Exit terminal insert mode and return to Normal mode.

---

## Linting on Save

An autocommand is set to trigger linting when a file is saved:

- **On file save (BufWritePost):**  
  _Action:_ Automatically executes `lua require('lint').try_lint()`.  
  _Description:_ This ensures that linting occurs immediately after saving the file.

---

## Further Reading

- [Neovim Key Mapping Documentation](https://neovim.io/doc/user/map.html) :contentReference[oaicite:4]{index=4}
- [Vim Cheat Sheet (vim.rtorr.com)](https://vim.rtorr.com/) :contentReference[oaicite:5]{index=5}
- [Neovim Lua API](https://neovim.io/doc/user/lua.html) :contentReference[oaicite:6]{index=6}
- [Telescope.nvim README](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-dap Documentation](https://github.com/mfussenegger/nvim-dap)

---

_This documentation is based on the custom configuration available at [SykesTheLord/NeoVimConfig](https://raw.githubusercontent.com/SykesTheLord/NeoVimConfig/refs/heads/main/init.vim) :contentReference[oaicite:7]{index=7}. Adjust and extend these mappings to best fit your workflow._
