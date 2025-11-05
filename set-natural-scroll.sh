#!/usr/bin/env bash
set -euo pipefail

# Set natural scrolling for touchpad, traditional scrolling for mouse
# Intended to run at i3 session start via: exec --no-startup-id ~/.config/i3/set-natural-scroll.sh

XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}

configure_xinput_scroll() {
  command -v xinput >/dev/null 2>&1 || return 0
  xinput --list --name-only 2>/dev/null | while IFS= read -r dev; do
    [ -z "$dev" ] && continue
    if xinput list-props "$dev" 2>/dev/null | grep -q "Natural Scrolling Enabled"; then
      # Check if device is a touchpad (contains "touchpad" or "trackpad" in name, case insensitive)
      if echo "$dev" | grep -iq "touchpad\|trackpad"; then
        # Enable natural scrolling for touchpad
        xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
      else
        # Disable natural scrolling for mouse/pointer
        xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 0 2>/dev/null || true
      fi
    fi
  done
}

configure_gnome_scroll() {
  command -v gsettings >/dev/null 2>&1 || return 0
  # Enable natural scroll for touchpad
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
  # Disable natural scroll for mouse
  gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false 2>/dev/null || true
}

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  configure_xinput_scroll
fi

configure_gnome_scroll

exit 0
