#!/usr/bin/env bash
# Show bell; add "!" when there are waiting notifications; DND shows alternate icon.
paused=$(dunstctl is-paused 2>/dev/null)
waiting=$(dunstctl count waiting 2>/dev/null)
if [[ "$paused" == "true" ]]; then
    # Your Waybar used a special "DND" glyph; use  here
    if (( waiting > 0 )); then
        echo "!"
    else
        echo ""
    fi
else
    if (( waiting > 0 )); then
        echo "!"
    else
        echo ""
    fi
fi

