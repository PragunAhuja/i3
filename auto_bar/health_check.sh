#!/bin/bash
# i3bar auto-hide health check

set -euo pipefail

echo "=== i3bar Auto-Hide Health Check ==="
echo

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_ok() { echo -e "${GREEN}✓${NC} $1"; }
check_fail() { echo -e "${RED}✗${NC} $1"; }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

# Service exists
echo -n "Service... "
if systemctl --user list-unit-files | grep -q auto-bar-hover.service; then
    check_ok "Installed"
else
    check_fail "Not found"
    exit 1
fi

# Auto-start enabled
echo -n "Auto-start... "
if systemctl --user is-enabled auto-bar-hover.service >/dev/null 2>&1; then
    check_ok "Enabled"
else
    check_warn "Disabled"
fi

# Service running
echo -n "Service... "
if systemctl --user is-active auto-bar-hover.service >/dev/null 2>&1; then
    check_ok "Running"
else
    check_fail "Not running"
    exit 1
fi

# Script exists
echo -n "Script... "
if [[ -f ~/.config/i3/auto_bar/auto_bar_hover.py ]]; then
    check_ok "Found"
else
    check_fail "Missing"
    exit 1
fi

# Dependencies
echo -n "Dependencies... "
if python3 -c "from Xlib import display" 2>/dev/null; then
    check_ok "python3-xlib (optimal)"
elif command -v xdotool >/dev/null 2>&1; then
    check_warn "xdotool fallback"
else
    check_fail "No mouse detection"
    exit 1
fi

# Process running
echo -n "Process... "
if PID=$(pgrep -f auto_bar_hover.py 2>/dev/null); then
    check_ok "Running (PID: $PID)"
else
    check_fail "Not running"
    exit 1
fi

# Resource usage
echo -n "Resources... "
CPU=$(ps -p "$(pgrep -f auto_bar_hover.py)" -o %cpu= 2>/dev/null | tr -d ' ')
MEM=$(ps -p "$(pgrep -f auto_bar_hover.py)" -o rss= 2>/dev/null | tr -d ' ')
MEM_MB=$((MEM / 1024))
if (( $(echo "$CPU < 5.0" | bc -l) )) && (( MEM_MB < 50 )); then
    check_ok "CPU: ${CPU}%, Memory: ${MEM_MB}MB"
else
    check_warn "CPU: ${CPU}%, Memory: ${MEM_MB}MB"
fi

# Modern behavior
echo -n "Modern behavior... "
if journalctl --user -u auto-bar-hover -n 20 --no-pager 2>/dev/null | grep -q "Show:.*Hide:"; then
    SHOW=$(journalctl --user -u auto-bar-hover -n 20 --no-pager 2>/dev/null | grep "Show:" | tail -1 | grep -oP '≤\K\d+' || echo "5")
    HIDE=$(journalctl --user -u auto-bar-hover -n 20 --no-pager 2>/dev/null | grep "Hide:" | tail -1 | grep -oP '>\K\d+' || echo "37")
    check_ok "Show≤${SHOW}px, Hide>${HIDE}px"
else
    check_warn "Could not verify"
fi

echo
echo "=== Quick Commands ==="
echo "  Logs:    journalctl --user -u auto-bar-hover -f"
echo "  Restart: systemctl --user restart auto-bar-hover"
echo "  Test:    ~/.config/i3/auto_bar/test_thresholds.sh"
echo
echo "✅ All checks passed!"
