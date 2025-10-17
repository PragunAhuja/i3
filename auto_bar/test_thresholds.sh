#!/bin/bash
# Visual demonstration of modern auto-hide behavior
# Shows real-time mouse position and bar state

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== i3bar Modern Auto-Hide Threshold Tester ==="
echo
echo "This will show you the current thresholds and track your mouse position."
echo "Move your mouse around to see when the bar should show/hide."
echo

# Get current configuration
BAR_HEIGHT=$(journalctl --user -u auto-bar-hover -n 100 --no-pager 2>/dev/null | grep "bar height:" | tail -1 | grep -oP '\d+(?=px)' || echo "32")
SHOW_THRESHOLD=$(journalctl --user -u auto-bar-hover -n 100 --no-pager 2>/dev/null | grep "Show threshold:" | tail -1 | grep -oP '\d+(?=px)' || echo "5")
HIDE_THRESHOLD=$(journalctl --user -u auto-bar-hover -n 100 --no-pager 2>/dev/null | grep "Hide threshold:" | tail -1 | grep -oP '\d+(?=px)' || echo "37")

echo -e "${BLUE}Current Configuration:${NC}"
echo -e "  Bar Height: ${BAR_HEIGHT}px"
echo -e "  Show Threshold: ${SHOW_THRESHOLD}px (from top)"
echo -e "  Hide Threshold: ${HIDE_THRESHOLD}px (from top)"
echo
echo -e "${YELLOW}Visual Guide:${NC}"
echo "┌────────────────────────────────────────┐ ← Y=0 (screen top)"
echo "│                                        │"
echo "│  ← SHOW ZONE (0-${SHOW_THRESHOLD}px)                   │"
echo "│                                        │"
echo "├────────────────────────────────────────┤ ← Y=~5px"
echo "│████████████ BAR AREA ████████████████ │ ← Bar appears here"
echo "│████████████ (stays open) █████████████│"
echo "├────────────────────────────────────────┤ ← Y=~${BAR_HEIGHT}px"
echo "│  ← STAY OPEN ZONE (${BAR_HEIGHT}-${HIDE_THRESHOLD}px)          │"
echo "├────────────────────────────────────────┤ ← Y=${HIDE_THRESHOLD}px (hide threshold)"
echo "│                                        │"
echo "│  ← HIDE ZONE (>${HIDE_THRESHOLD}px)                 │"
echo "│                                        │"
echo "│         Normal workspace              │"
echo "│                                        │"
echo "└────────────────────────────────────────┘"
echo
echo -e "${GREEN}Press Ctrl+C to exit${NC}"
echo
echo "Tracking mouse position..."
echo

# Track mouse and show state
while true; do
    if command -v xdotool >/dev/null 2>&1; then
        Y=$(xdotool getmouselocation --shell | grep Y= | cut -d= -f2)
        
        if [ "$Y" -le "$SHOW_THRESHOLD" ]; then
            STATE="${GREEN}SHOW BAR${NC} (mouse at top edge)"
        elif [ "$Y" -le "$HIDE_THRESHOLD" ]; then
            STATE="${YELLOW}BAR STAYS OPEN${NC} (hovering over bar)"
        else
            STATE="${RED}HIDE BAR${NC} (mouse away from bar)"
        fi
        
        printf "\rMouse Y: %4d px | State: $STATE     " "$Y"
    else
        echo "xdotool not found. Install with: sudo apt install xdotool"
        exit 1
    fi
    
    sleep 0.1
done
