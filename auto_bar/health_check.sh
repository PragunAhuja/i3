#!/bin/bash
# Production deployment and health check script
# Run this after system restart to verify everything works

set -euo pipefail

echo "=== i3bar Auto-Hide Production Health Check (v3.0) ==="
echo "    Modern Behavior Edition"
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check 1: Service exists
echo -n "Checking systemd service... "
if systemctl --user list-unit-files | grep -q auto-bar-hover.service; then
    check_ok "Service installed"
else
    check_fail "Service not found"
    exit 1
fi

# Check 2: Service is enabled
echo -n "Checking auto-start... "
if systemctl --user is-enabled auto-bar-hover.service >/dev/null 2>&1; then
    check_ok "Auto-start enabled"
else
    check_warn "Auto-start disabled (run: systemctl --user enable auto-bar-hover)"
fi

# Check 3: Service is running
echo -n "Checking service status... "
if systemctl --user is-active auto-bar-hover.service >/dev/null 2>&1; then
    check_ok "Service running"
else
    check_fail "Service not running (run: systemctl --user start auto-bar-hover)"
    exit 1
fi

# Check 4: Script exists and is executable
echo -n "Checking script... "
if [[ -x ~/.config/i3/auto_bar/auto_bar_hover_v2.py ]]; then
    check_ok "Script executable"
else
    check_fail "Script not found or not executable"
    exit 1
fi

# Check 5: Dependencies
echo -n "Checking dependencies... "
if python3 -c "from Xlib import display" 2>/dev/null; then
    check_ok "python3-xlib installed (optimal)"
elif command -v xdotool >/dev/null 2>&1; then
    check_warn "Using xdotool fallback (install python3-xlib for better performance)"
else
    check_fail "No mouse detection available (install python3-xlib or xdotool)"
    exit 1
fi

# Check 6: Process running
echo -n "Checking process... "
if pgrep -f auto_bar_hover_v2.py >/dev/null 2>&1; then
    PID=$(pgrep -f auto_bar_hover_v2.py)
    check_ok "Process running (PID: $PID)"
else
    check_fail "Process not running"
    exit 1
fi

# Check 7: Resource usage
echo -n "Checking resource usage... "
CPU=$(ps -p "$(pgrep -f auto_bar_hover_v2.py)" -o %cpu= | tr -d ' ')
MEM=$(ps -p "$(pgrep -f auto_bar_hover_v2.py)" -o rss= | tr -d ' ')
MEM_MB=$((MEM / 1024))
if (( $(echo "$CPU < 5.0" | bc -l) )) && (( MEM_MB < 50 )); then
    check_ok "CPU: ${CPU}%, Memory: ${MEM_MB}MB (within limits)"
else
    check_warn "CPU: ${CPU}%, Memory: ${MEM_MB}MB (check if excessive)"
fi

# Check 8: Log file
echo -n "Checking logs... "
if [[ -f /tmp/auto_bar_hover.log ]]; then
    LINES=$(wc -l < /tmp/auto_bar_hover.log)
    check_ok "Log file exists ($LINES lines)"
else
    check_warn "No log file found"
fi

# Check 9: i3 bar configuration
echo -n "Checking i3 bar config... "
if BAR_MODE=$(i3-msg -t get_bar_config bar-0 2>/dev/null | grep -o '"mode":"[^"]*"' | cut -d'"' -f4) && \
   BAR_MODIFIER=$(i3-msg -t get_bar_config bar-0 2>/dev/null | grep -o '"modifier":"[^"]*"' | cut -d'"' -f4); then
    if [[ "$BAR_MODE" == "hide" ]] && [[ "$BAR_MODIFIER" == "Mod4" ]]; then
        check_ok "i3 bar configured correctly (mode: hide, modifier: Mod4)"
    else
        check_warn "i3 bar config: mode=$BAR_MODE, modifier=$BAR_MODIFIER"
    fi
else
    check_warn "Could not query i3 bar config"
fi

# Check 10: Recent activity
echo -n "Checking recent activity... "
if [[ -f /tmp/auto_bar_hover.log ]]; then
    LAST_LOG=$(tail -1 /tmp/auto_bar_hover.log 2>/dev/null || echo "")
    if [[ -n "$LAST_LOG" ]]; then
        check_ok "Script active (last log: $(date -r /tmp/auto_bar_hover.log '+%H:%M:%S'))"
    else
        check_warn "No recent activity in logs"
    fi
fi

# Check 11: Modern behavior configuration
echo -n "Checking modern behavior... "
if journalctl --user -u auto-bar-hover -n 50 --no-pager 2>/dev/null | grep -q "Hide threshold:"; then
    SHOW_TH=$(journalctl --user -u auto-bar-hover -n 50 --no-pager 2>/dev/null | grep "Show threshold:" | tail -1 | grep -oP '\d+(?=px)' || echo "?")
    HIDE_TH=$(journalctl --user -u auto-bar-hover -n 50 --no-pager 2>/dev/null | grep "Hide threshold:" | tail -1 | grep -oP '\d+(?=px)' || echo "?")
    BAR_H=$(journalctl --user -u auto-bar-hover -n 50 --no-pager 2>/dev/null | grep "bar height:" | tail -1 | grep -oP '\d+(?=px)' || echo "?")
    check_ok "Modern behavior active (show:${SHOW_TH}px, hide:${HIDE_TH}px, bar:${BAR_H}px)"
else
    check_warn "Could not verify modern behavior settings"
fi

echo
echo "=== Summary ==="
echo "All critical checks passed! ✓"
echo
echo "Quick commands:"
echo "  View logs:     journalctl --user -u auto-bar-hover -f"
echo "  Restart:       systemctl --user restart auto-bar-hover"
echo "  Status:        systemctl --user status auto-bar-hover"
echo "  Test thresholds: ~/.config/i3/auto_bar/test_thresholds.sh"
echo
echo "Test functionality (Modern Behavior):"
echo "  1. Move mouse to top of screen (≤5px) → bar appears"
echo "  2. Keep mouse over bar → bar stays open (modern!)"
echo "  3. Move mouse below bar (>37px) → bar disappears"
echo "  4. Press Mod (Windows) key → bar shows while held"
echo "  5. Press Mod+b → bar switches to dock mode (no jitter)"
echo
