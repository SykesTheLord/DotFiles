#!/usr/bin/env bash
# Pull workspace $1 to the focused monitor (if elsewhere), then focus it.
# Replacement for hyprland/workspaces `move-to-monitor: true`, which is broken
# under Hyprland's Lua dispatch API (waybar emits hl.dsp.focus with a
# `monitor="current"` key that the focus dispatcher silently ignores).
set -eu
ws="$1"
focused_mon=$(hyprctl -j activeworkspace | jq -r '.monitor')
ws_mon=$(hyprctl -j workspaces | jq -r --arg ws "$ws" '.[] | select(.name==$ws) | .monitor')
if [ -n "$ws_mon" ] && [ "$ws_mon" != "$focused_mon" ]; then
  hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$ws\", monitor = \"$focused_mon\" })" >/dev/null
fi
hyprctl dispatch "hl.dsp.focus({ workspace = \"$ws\" })" >/dev/null
