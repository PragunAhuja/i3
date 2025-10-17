#!/bin/bash
# Startup wrapper for auto_bar_hover.py
# This ensures the script starts cleanly from i3 config

# Kill any existing instances
pkill -f auto_bar_hover.py 2>/dev/null

# Small delay to ensure clean kill
sleep 0.2

# Start the hover script
exec /home/pragun/.config/i3/auto_bar/auto_bar_hover.py
