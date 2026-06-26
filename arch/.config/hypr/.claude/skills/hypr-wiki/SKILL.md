---
name: hypr-wiki
description: Look up an option, keyword, or page from the official Hyprland wiki when working in this Hyprland config. Use when you need authoritative syntax/behavior for a Hyprland feature instead of guessing.
---

# hypr-wiki

The Hyprland wiki source lives at https://github.com/hyprwm/hyprland-wiki under `pages/`. The rendered site is https://wiki.hypr.land.

## How to look something up

1. If you don't already know the page path, list the tree:
   ```
   curl -sL "https://api.github.com/repos/hyprwm/hyprland-wiki/git/trees/main?recursive=1" | grep -i '<keyword>'
   ```
2. Fetch the raw markdown for the page you want:
   ```
   curl -s https://raw.githubusercontent.com/hyprwm/hyprland-wiki/main/pages/<path>.md
   ```
3. Or WebFetch from `https://wiki.hypr.land/<path>/` for the rendered version.

These fetch patterns are pre-allowlisted in `.claude/settings.local.json`.

## When to invoke

- The user asks about a Hyprland option, dispatcher, rule, or env var and you're not certain of the exact syntax.
- Before adding a `hl.config({...})` block or window/layer rule, verify field names and accepted values.
- When migrating something from a `.bak` `.conf` file, confirm the Lua-API equivalent.

Prefer the wiki over inferring from existing `hyprland.lua` patterns — the wiki is authoritative.
