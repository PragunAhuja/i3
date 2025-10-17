#!/bin/bash
# Toggle bar between dock (takes space) and hide modes
# This is for Mod+b keybinding - makes bar take window space

LOG_FILE="/tmp/toggle_bar_dock.log"

current_mode=$(i3-msg -t get_bar_config bar-0 2>/dev/null | grep -o '"mode":"[^"]*"' | cut -d'"' -f4)
echo "[$(date '+%H:%M:%S')] Current mode: $current_mode" >> "$LOG_FILE"

case "$current_mode" in
    "invisible"|"visible")
        # Coming from hover mode -> switch to dock (visible, takes space)
        echo "[$(date '+%H:%M:%S')] Switching to dock mode" >> "$LOG_FILE"
        i3-msg 'bar mode dock'
        ;;
    "dock")
        # Currently docked -> hide it (but keep space reserved)
        echo "[$(date '+%H:%M:%S')] Hiding bar (keeping space)" >> "$LOG_FILE"
        i3-msg 'bar mode hide'
        ;;
    "hide")
        # Currently hidden -> show as dock again
        echo "[$(date '+%H:%M:%S')] Showing bar in dock mode" >> "$LOG_FILE"
        i3-msg 'bar mode dock'
        ;;
    *)
        # Fallback: default to dock
        echo "[$(date '+%H:%M:%S')] Fallback: switching to dock mode" >> "$LOG_FILE"
        i3-msg 'bar mode dock'
        ;;
esac
