# i3bar Auto-Hide Changelog

## v3.0 - Modern Behavior (October 18, 2025)
**Major Features:**
- Dual-threshold system: Show at ≤5px, hide at >(bar_height + 5px)
- Bar stays open while hovering (modern UX like GNOME/KDE/macOS)
- Adaptive bar height detection via xdotool window geometry
- Smart hover zone: bar area + 5px padding
- Enhanced logging with mouse Y position tracking

**Technical Improvements:**
- Simplified to single production script (224 lines)
- Auto-detects bar height (32px typical)
- Zero configuration needed for threshold calculation
- Robust systemd service (uses python3 explicitly, no shebang dependency)
- Waits for i3 readiness before starting

**Bug Fixes:**
- Fixed permission issues by using explicit python3 execution
- Eliminated jitter in dock mode via mode detection
- Proper i3 startup synchronization

## v2.0 - Production Ready (October 17, 2025)
**Major Features:**
- Simplified codebase from 336 to 159 lines
- Removed state file complexity (stateless design)
- Jitter-free dock mode operation
- Resource limits via systemd (5% CPU, 50MB RAM)
- Comprehensive health check script

**Technical Improvements:**
- Mode detection prevents hover/dock conflicts
- Singleton guard prevents multiple instances
- Auto-restart on failure
- Consolidated documentation (5 files → 1)

## v1.0 - Initial Release (October 16, 2025)
**Features:**
- Mouse hover auto-show/hide
- Mod+b dock mode toggle
- Xlib polling with xdotool fallback
- State persistence across restarts
- Systemd service integration

**Performance:**
- ~0.1% CPU usage
- ~16MB memory footprint
- 100ms poll interval
- 80ms debounce

---

## Configuration History

### Current Settings
- Show threshold: 5px from top
- Hide threshold: Auto (bar_height + 5px)
- Poll interval: 0.1s
- Debounce: 0.08s
- Bar padding: 5px

### Service Evolution
- v1.0: Basic systemd service
- v2.0: Added resource limits
- v3.0: Added i3 readiness check, explicit python3 execution

---

## Known Issues & Fixes

### Issue: Permission Denied on Restart
**Symptom:** Service fails with "Permission denied" after file edits  
**Root Cause:** File edits remove execute permission  
**Fix:** Use `ExecStart=/usr/bin/python3 script.py` instead of direct execution  
**Status:** Fixed in v3.0

### Issue: Bar Doesn't Start on Boot
**Symptom:** Service starts before i3 is ready  
**Root Cause:** Race condition with i3 startup  
**Fix:** Added `ExecStartPre` wait for i3 socket/version  
**Status:** Fixed in v3.0

### Issue: Jitter in Dock Mode
**Symptom:** Display flickers when mouse moves and bar is docked  
**Root Cause:** Hover script toggles hidden_state while in dock mode  
**Fix:** Detect dock/invisible mode and skip hover logic  
**Status:** Fixed in v2.0

---

## Migration Guide

### Upgrading from v2.0 to v3.0
1. Update systemd service (automatic via file replacement)
2. Replace auto_bar_hover.py with v3.0 script
3. Reload: `systemctl --user daemon-reload`
4. Restart: `systemctl --user restart auto-bar-hover`
5. Verify: Check logs show "Show: ≤5px | Hide: >37px"

### Upgrading from v1.0 to v2.0
1. Remove .bar_state file (no longer used)
2. Update to simplified script
3. Reload systemd: `systemctl --user daemon-reload`
4. Restart service

---

## Troubleshooting Log

### Auto-Start Issues
- **Check service status:** `systemctl --user status auto-bar-hover`
- **Check logs:** `journalctl --user -u auto-bar-hover -n 50`
- **Common fix:** `systemctl --user daemon-reload && systemctl --user restart auto-bar-hover`

### Bar Not Responding
- **Check if running:** `pgrep -a auto_bar_hover`
- **Check i3 connection:** `i3-msg -t get_bar_config bar-0`
- **Restart manually:** `systemctl --user restart auto-bar-hover`

### High CPU Usage
- **Check actual usage:** `ps aux | grep auto_bar_hover`
- **Verify limits:** `systemctl --user show auto-bar-hover | grep CPU`
- **Adjust poll interval:** Set `AUTO_BAR_POLL_INTERVAL=0.2` in service

---

## Removed Features
- State file persistence (v1.0) - Replaced with stateless design in v2.0
- Complex pinned/unpinned state management (v1.0) - Simplified to mode detection in v2.0
- Separate v2 script file (v3.0) - Consolidated into single auto_bar_hover.py

## Deprecated Files
- `auto_bar_hover_v2.py` - Use `auto_bar_hover.py` instead
- `start_auto_bar_hover.sh` - Replaced by systemd ExecStart
- `.bar_state` - No longer needed (stateless design)
