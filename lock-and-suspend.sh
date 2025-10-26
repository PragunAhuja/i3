#!/bin/bash
# Lock screen with blur effect and suspend after 30 seconds if still locked

i3lock-fancy -n -p -- scrot -z &

# Wait 30 seconds
sleep 30

# Check if i3lock is still running (screen still locked)
if pgrep -x i3lock > /dev/null; then
    # Kill i3lock before suspending to prevent lock-failed message
    pkill -x i3lock
    systemctl suspend
fi
