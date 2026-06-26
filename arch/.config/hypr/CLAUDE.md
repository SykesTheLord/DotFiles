# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal Hyprland window manager configuration. Single-file Lua config at `hyprland.lua` (migrated from the legacy `.conf` format). Uses the `hl.*` API: `hl.monitor`, `hl.env`, `hl.on`, `hl.config`, `hl.permission`, `hl.exec_cmd`, `hl.bind`, etc. See https://wiki.hypr.land/Configuring/Start/.

Other files:
- `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf` — still use the legacy `.conf` format (these tools haven't migrated to Lua).
- `components/*.bak` and `hyprland.conf.bak` — pre-migration reference only. **Do not edit.** They are not sourced.
- `components/lid-actions.conf` — the only active `.conf` in `components/`.
- `UserScripts/` — helper shell scripts invoked from keybinds / autostart.

## Editing rules

- Make all Hyprland changes in `hyprland.lua`, not in any `.bak` file.
- Do not run `hyprctl reload` or otherwise try to apply changes — the user reloads manually.
- Not a git repo. Don't suggest `git` commands here.

## Looking things up

When unsure about a Hyprland option, keyword, or rule syntax, fetch from the official wiki rather than guessing. The `/hypr-wiki` skill has the allowlisted fetch patterns.
