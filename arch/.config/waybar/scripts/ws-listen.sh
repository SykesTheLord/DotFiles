#!/usr/bin/env bash
# Stream Hyprland events; signal waybar (SIGRTMIN+1) on workspace/monitor changes
# so the custom/ws-* modules refresh. Autostart via Hyprland exec-once.
set -eu
sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:?}/.socket2.sock"

socat -U - "UNIX-CONNECT:$sock" | while IFS= read -r line; do
  case "$line" in
    workspace*|focusedmon*|moveworkspace*|createworkspace*|destroyworkspace*|activespecial*)
      pkill -RTMIN+1 waybar || true
      ;;
  esac
done
