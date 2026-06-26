---
name: reload-waybar
description: Reload the running Waybar instance so config/style changes take effect. Sends SIGUSR2 (graceful config reload). Use after editing config.jsonc, modules.json, style.css, or waybar.css.
disable-model-invocation: true
---

Run:

```bash
pkill -SIGUSR2 waybar
```

If `pkill` returns non-zero, Waybar isn't running — tell the user to start it from their Hyprland autostart (don't background-launch it from this session).

After reloading, briefly note what should now be visible (e.g., "new module added to modules-right; check the bar").
