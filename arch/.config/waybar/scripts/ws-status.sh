#!/usr/bin/env bash
# Emit waybar JSON for workspace $1.
#   class "active"  = workspace is visible on some monitor
#   class "focused" = workspace is the globally focused one
#   class "empty"   = no windows on the workspace
set -eu
ws="$1"

workspaces=$(hyprctl -j workspaces)
monitors=$(hyprctl -j monitors)
focused_ws=$(hyprctl -j activeworkspace | jq -r '.name')

windows=$(jq -r --arg ws "$ws" '(map(select(.name==$ws)) | .[0].windows) // 0' <<<"$workspaces")
visible=$(jq -r --arg ws "$ws" '[.[] | select(.activeWorkspace.name==$ws)] | length' <<<"$monitors")

classes=()
[ "$visible" -gt 0 ] && classes+=("active")
[ "$focused_ws" = "$ws" ] && classes+=("focused")
[ "$windows" = "0" ] && classes+=("empty")

text="$ws"

class_json=$(printf '%s\n' "${classes[@]+"${classes[@]}"}" | jq -R . | jq -sc .)
jq -nc --arg text "$text" --argjson class "$class_json" \
  '{text:$text, class:$class, tooltip:"Workspace " + ($text|tostring)}'
