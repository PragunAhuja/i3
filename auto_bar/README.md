# i3bar Modern Auto-Hide

Production-grade auto-hide i3bar with modern behavior.

## Quick Start

```bash
# Test it works
systemctl --user status auto-bar-hover

# Move mouse to top → bar appears
# Keep mouse over bar → bar stays open (modern!)
# Move mouse away → bar disappears

# Press Mod+b → toggle dock mode
```

## Features

✅ **Modern Behavior** - Bar stays open while hovering (like GNOME/KDE)  
✅ **Adaptive Height** - Auto-detects bar height for optimal thresholds  
✅ **Zero Jitter** - Smart mode detection prevents conflicts  
✅ **Production Ready** - Systemd service, resource limits, auto-restart  
✅ **Minimal Resources** - <0.5% CPU, ~20MB RAM

## How It Works

### Show/Hide Logic
- **Show:** Mouse ≤5px from top
- **Stay Open:** Mouse between 6px and (bar_height + 5px)
- **Hide:** Mouse >(bar_height + 5px)

Your bar is 32px tall, so:
- Show trigger: 0-5px
- Hover zone: 6-37px (bar stays visible)
- Hide trigger: >37px

### Operating Modes
1. **Hover Mode** (default): Overlay, no window resize
2. **Dock Mode** (Mod+b): Takes space, windows resize
3. **Mod Key** (Windows): Shows while held

## Configuration

Edit service: `systemctl --user edit auto-bar-hover.service`

```ini
[Service]
# Show sensitivity (default: 5px)
Environment="AUTO_BAR_SHOW_THRESHOLD=3"

# Hide padding below bar (default: 5px)  
Environment="AUTO_BAR_PADDING=10"

# Poll interval (default: 0.1s)
Environment="AUTO_BAR_POLL_INTERVAL=0.05"

# Enable logging (default: enabled)
Environment="AUTO_BAR_LOG=1"
```

Apply changes:
```bash
systemctl --user daemon-reload
systemctl --user restart auto-bar-hover
```

## Management

```bash
# Check status
systemctl --user status auto-bar-hover

# View logs
journalctl --user -u auto-bar-hover -f
tail -f /tmp/auto_bar_hover.log

# Restart
systemctl --user restart auto-bar-hover

# Health check
~/.config/i3/auto_bar/health_check.sh

# Visual threshold tester
~/.config/i3/auto_bar/test_thresholds.sh
```

## Troubleshooting

### Bar doesn't start on boot
Check service logs:
```bash
journalctl --user -u auto-bar-hover -n 50
systemctl --user status auto-bar-hover
```

Fix:
```bash
systemctl --user daemon-reload
systemctl --user restart auto-bar-hover
```

### Bar not responding to mouse
1. Check if running: `pgrep -a auto_bar_hover`
2. Check i3 connection: `i3-msg -t get_bar_config bar-0`
3. Restart: `systemctl --user restart auto-bar-hover`

### High CPU usage
Check actual usage:
```bash
ps aux | grep auto_bar_hover
systemctl --user show auto-bar-hover | grep CPU
```

Reduce poll frequency:
```bash
systemctl --user edit auto-bar-hover.service
# Add: Environment="AUTO_BAR_POLL_INTERVAL=0.2"
systemctl --user daemon-reload && systemctl --user restart auto-bar-hover
```

## File Structure

```
~/.config/i3/auto_bar/
├── auto_bar_hover.py       # Main script (production)
├── health_check.sh          # System diagnostics
├── test_thresholds.sh       # Visual threshold tester
├── README.md                # This file
└── CHANGELOG.md             # Version history

~/.config/systemd/user/
└── auto-bar-hover.service   # Systemd service

/tmp/auto_bar_hover.log      # Runtime logs
```

## Technical Details

### Dependencies
- **Required:** python3, i3-wm
- **Optimal:** python3-xlib (fastest mouse detection)
- **Fallback:** xdotool (if Xlib not available)

### Performance
- CPU: 0.1-0.5% typical (5% max limit)
- Memory: ~20MB (50MB max limit)
- Poll: 100ms interval
- Debounce: 80ms

### Bar Control
- Overlay: `i3-msg bar hidden_state show|hide`
- Dock: `i3-msg bar mode dock|hide`
- Mode query: `i3-msg -t get_bar_config bar-0`

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and upgrade notes.

## License

MIT
