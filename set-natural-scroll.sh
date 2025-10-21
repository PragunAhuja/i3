#!/usr/bin/env bash
set -euo pipefail

# Enable libinput "Natural Scrolling" for X11 devices and GNOME settings
# Intended to run at i3 session start via: exec --no-startup-id ~/.config/i3/set-natural-scroll.sh

XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}

enable_xinput_natural() {
  command -v xinput >/dev/null 2>&1 || return 0
  xinput --list --name-only 2>/dev/null | while IFS= read -r dev; do
    [ -z "$dev" ] && continue
    if xinput list-props "$dev" 2>/dev/null | grep -q "Natural Scrolling Enabled"; then
      cur=$(xinput list-props "$dev" 2>/dev/null | awk -F: '/Natural Scrolling Enabled/ {gsub(/[^0-9]/,"",$2); print $2; exit}')
      [ -z "${cur:-}" ] && cur=$(xinput list-props "$dev" 2>/dev/null | awk '/Natural Scrolling Enabled/ {print $NF; exit}')
      if [ "${cur:-}" = "0" ]; then
        xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
      fi
    fi
  done
}

enable_gnome_natural() {
  command -v gsettings >/dev/null 2>&1 || return 0
  if gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null | grep -q "false"; then
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
  fi
  if gsettings get org.gnome.desktop.peripherals.mouse natural-scroll 2>/dev/null | grep -q "false"; then
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true 2>/dev/null || true
  fi
}

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  enable_xinput_natural
fi

enable_gnome_natural

exit 0
