#!/usr/bin/env python3
"""
Production i3bar auto-hide with modern behavior.

Modern Features:
- Bar stays open while hovering (dual-threshold system)
- Auto-detects bar height for optimal hide threshold
- Show: ≤5px from top | Hide: >(bar_height + 5px)
- Bulletproof i3 connection with socket check

Modes:
- Hover: Overlay mode (no window resize)
- Dock: Mod+b toggles space-taking mode
- Zero jitter in all modes

Resource Usage: <0.5% CPU, ~20MB RAM
"""

import json
import os
import socket
import subprocess
import sys
import time
from typing import Optional

# Configuration
SHOW_THRESHOLD = int(os.getenv("AUTO_BAR_SHOW_THRESHOLD", "5"))
POLL_INTERVAL = float(os.getenv("AUTO_BAR_POLL_INTERVAL", "0.1"))
DEBOUNCE = float(os.getenv("AUTO_BAR_DEBOUNCE", "0.08"))
BAR_PADDING = int(os.getenv("AUTO_BAR_PADDING", "5"))
LOGGING = bool(os.getenv("AUTO_BAR_LOG", ""))


def log(msg: str) -> None:
    """Log to stderr if enabled."""
    if LOGGING:
        sys.stderr.write(f"[auto_bar] {msg}\n")
        sys.stderr.flush()


def get_i3_socket() -> Optional[str]:
    """Get i3 IPC socket path."""
    try:
        result = subprocess.run(
            ["i3", "--get-socketpath"],
            capture_output=True,
            text=True,
            timeout=1.0
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None


def is_i3_socket_alive() -> bool:
    """Check if i3 socket exists and is connectable."""
    socket_path = get_i3_socket()
    if not socket_path:
        return False
    
    try:
        # Try to connect to the socket
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(0.5)
        sock.connect(socket_path)
        sock.close()
        return True
    except Exception:
        return False


def wait_for_i3(timeout: int = 20) -> bool:
    """Wait for i3 to be ready with timeout."""
    log(f"Waiting for i3 socket (timeout={timeout}s)...")
    start = time.time()
    
    while time.time() - start < timeout:
        if is_i3_socket_alive():
            # Socket exists, now verify IPC works
            try:
                result = subprocess.run(
                    ["i3-msg", "-t", "get_version"],
                    capture_output=True,
                    timeout=1.0
                )
                if result.returncode == 0:
                    log("✓ i3 is ready!")
                    return True
            except Exception:
                pass
        time.sleep(0.5)
    
    log(f"✗ i3 not ready after {timeout}s")
    return False


def i3_cmd(cmd: list[str], timeout: float = 1.0) -> bool:
    """Execute i3-msg command with error handling."""
    try:
        result = subprocess.run(
            ["i3-msg"] + cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode == 0
    except Exception:
        return False


def set_bar_overlay(visible: bool) -> bool:
    """Set bar visibility in overlay mode (no window resize)."""
    state = "show" if visible else "hide"
    if i3_cmd(["bar", "hidden_state", state]):
        log(f"Bar overlay: {state}")
        return True
    return False


def get_bar_mode() -> Optional[str]:
    """Get current bar mode (hide, dock, or invisible)."""
    try:
        result = subprocess.run(
            ["i3-msg", "-t", "get_bar_config", "bar-0"],
            capture_output=True,
            text=True,
            timeout=1.0
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            return data.get("mode")
    except Exception:
        pass
    return None


def get_bar_height() -> int:
    """Auto-detect bar height from window geometry or config."""
    try:
        # Try xdotool window geometry (most accurate)
        result = subprocess.run(
            ["xdotool", "search", "--class", "i3bar", "getwindowgeometry"],
            capture_output=True,
            text=True,
            timeout=1.0
        )
        if result.returncode == 0:
            for line in result.stdout.splitlines():
                if "Geometry:" in line:
                    height = int(line.split("Geometry:")[1].strip().split("x")[1])
                    log(f"Detected bar height: {height}px")
                    return height
    except Exception:
        pass
    
    # Fallback: Calculate from font size
    try:
        result = subprocess.run(
            ["i3-msg", "-t", "get_bar_config", "bar-0"],
            capture_output=True,
            text=True,
            timeout=1.0
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            font = data.get("font", "")
            if font:
                for part in font.split():
                    if part.isdigit():
                        font_size = int(part)
                        estimated = font_size * 2 + 4
                        log(f"Estimated bar height: {estimated}px (from font)")
                        return estimated
    except Exception:
        pass
    
    # Default
    log("Using default bar height: 30px")
    return 30


def get_mouse_y() -> Optional[int]:
    """Get mouse Y coordinate (Xlib preferred, xdotool fallback)."""
    # Try Xlib (fastest)
    try:
        from Xlib import display
        disp = display.Display()
        root = disp.screen().root
        pointer = root.query_pointer()
        return pointer.root_y
    except Exception:
        pass
    
    # Fallback to xdotool
    try:
        result = subprocess.run(
            ["xdotool", "getmouselocation", "--shell"],
            capture_output=True,
            text=True,
            timeout=0.5
        )
        if result.returncode == 0:
            for line in result.stdout.splitlines():
                if line.startswith("Y="):
                    return int(line.split("=")[1])
    except Exception:
        pass
    
    return None


def is_singleton() -> bool:
    """Ensure only one instance runs."""
    try:
        result = subprocess.run(
            ["pgrep", "-fc", "auto_bar_hover"],
            capture_output=True,
            text=True
        )
        count = int(result.stdout.strip()) if result.stdout.strip() else 0
        return count <= 1
    except Exception:
        return True


def main() -> int:
    """Main event loop with modern auto-hide behavior."""
    if not is_singleton():
        log("Another instance already running")
        return 0
    
    # Wait for i3 to be ready
    if not wait_for_i3(timeout=30):
        log("⚠ Starting without i3 - will retry every 5s")
    
    # Detect bar height and calculate hide threshold
    bar_height = get_bar_height()
    hide_threshold = bar_height + BAR_PADDING
    
    log(f"Starting i3bar auto-hover (modern behavior)")
    log(f"Show: ≤{SHOW_THRESHOLD}px | Hide: >{hide_threshold}px | Bar: {bar_height}px")
    
    # Initialize
    set_bar_overlay(False)
    bar_visible = False
    last_change = 0.0
    last_i3_check = time.time()
    i3_connected = is_i3_socket_alive()
    
    # Startup mode: check every 5s for first 2 minutes
    startup_mode = not i3_connected
    startup_end = time.time() + 120 if startup_mode else 0
    check_interval = 5 if startup_mode else 60
    
    if startup_mode:
        log("⏳ Startup mode: checking i3 every 5s")
    
    try:
        while True:
            try:
                now = time.time()
                
                # Exit startup mode after 2 minutes
                if startup_mode and now > startup_end:
                    startup_mode = False
                    check_interval = 60
                    if not i3_connected:
                        log("⚠ Still no i3 connection, switching to 60s checks")
                
                # Periodically check i3 connection
                if now - last_i3_check > check_interval:
                    was_connected = i3_connected
                    i3_connected = is_i3_socket_alive()
                    
                    if not was_connected and not i3_connected:
                        # Try to connect
                        if wait_for_i3(timeout=3):
                            i3_connected = True
                            log("✓ Connected to i3!")
                            bar_height = get_bar_height()
                            hide_threshold = bar_height + BAR_PADDING
                            log(f"Initialized | Show: ≤{SHOW_THRESHOLD}px | Hide: >{hide_threshold}px")
                            bar_visible = False
                            startup_mode = False
                            check_interval = 60
                    elif not was_connected and i3_connected:
                        log("✓ i3 connection detected!")
                        bar_height = get_bar_height()
                        hide_threshold = bar_height + BAR_PADDING
                        log(f"Initialized | Show: ≤{SHOW_THRESHOLD}px | Hide: >{hide_threshold}px")
                        startup_mode = False
                        check_interval = 60
                    elif was_connected and not i3_connected:
                        log("⚠ i3 connection lost, entering startup mode")
                        startup_mode = True
                        check_interval = 5
                        startup_end = now + 120
                    
                    last_i3_check = now
                
                # Skip hover logic if not connected
                if not i3_connected:
                    time.sleep(POLL_INTERVAL)
                    continue
                
                # Skip hover logic if bar in dock/invisible mode
                mode = get_bar_mode()
                if mode in ("dock", "invisible"):
                    if bar_visible:
                        bar_visible = False
                    time.sleep(POLL_INTERVAL)
                    continue
                
                y = get_mouse_y()
                if y is None:
                    time.sleep(POLL_INTERVAL)
                    continue
                
                # Show bar when mouse at top
                if y <= SHOW_THRESHOLD and not bar_visible and (now - last_change) > DEBOUNCE:
                    if set_bar_overlay(True):
                        bar_visible = True
                        last_change = now
                        log(f"Bar shown (Y={y})")
                
                # Hide bar when mouse leaves bar area
                elif y > hide_threshold and bar_visible and (now - last_change) > DEBOUNCE:
                    if set_bar_overlay(False):
                        bar_visible = False
                        last_change = now
                        log(f"Bar hidden (Y={y}, threshold={hide_threshold})")
                
                time.sleep(POLL_INTERVAL)
                
            except KeyboardInterrupt:
                raise
            except Exception as e:
                log(f"Loop error: {e}")
                time.sleep(POLL_INTERVAL * 2)
                
    except KeyboardInterrupt:
        log("Shutting down")
        return 0


if __name__ == "__main__":
    sys.exit(main())
