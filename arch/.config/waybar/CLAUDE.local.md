# CLAUDE.local.md

Personal notes for working in this Waybar config directory.

## Context
- Not a git repo. Plain Waybar config: `config.jsonc` (bar layout) + `modules.json` (included via `"include"`) + `style.css` (GTK CSS) + `waybar.css`.
- Compositor is Hyprland; layout uses `hyprland/workspaces`, `hyprland/window`.

## Workflow
- After editing `config.jsonc`, `modules.json`, `style.css`, or `waybar.css`: reload with `pkill -SIGUSR2 waybar` (graceful config reload). If Waybar isn't running yet, start it via Hyprland's autostart, not from this shell.
- `config.jsonc` is JSON-with-comments. To validate: `sed 's|//.*||' config.jsonc | jq .`. `modules.json` is plain JSON — `jq . modules.json` works directly.
- `style.css` is GTK CSS, not browser CSS. Selectors are `#module-name` (e.g. `#clock`, `#custom-arch`); module names with `/` become `-` (e.g. `custom/arch` → `#custom-arch`). Properties are a GTK subset — no `box-shadow` blur, limited transitions, `border-radius` works.

## Gotchas
- The `tray` module is nested inside `group/tray-expander` in `modules.json`, not listed directly in `modules-right`. Don't add a duplicate.
- `format-icons` uses Nerd Font glyphs (CaskaydiaMono Nerd Font). Render in a Nerd-Font terminal when reading diffs.
