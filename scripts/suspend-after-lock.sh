#!/bin/bash
# Monitor for i3lock and auto-suspend after 30 seconds

while true; do
    if pgrep -x i3lock > /dev/null; then
        # i3lock is running, wait 30 seconds
        sleep 30
        
        # Check if still locked
        if pgrep -x i3lock > /dev/null; then
            systemctl suspend
        fi
    fi
    
    # Check every 5 seconds
    sleep 5
done
