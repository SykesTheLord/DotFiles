#!/usr/bin/env bash
# Icons mirror your Waybar mapping: performance= balanced= power-saver=
cur="$(powerprofilesctl get 2>/dev/null)"
case "$cur" in
    performance) echo "" ;;
    balanced)    echo "" ;;
    power-saver) echo "" ;;
    *)           echo "" ;;
esac

