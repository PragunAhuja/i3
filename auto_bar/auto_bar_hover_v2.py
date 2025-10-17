#!/usr/bin/env python3
"""
Production-grade i3bar auto-show/hide with modern behavior.

Features:
- Modern hover behavior: Bar stays open until cursor leaves bar area
- Mouse hover: Bar overlays (no window resize) using hidden_state
- Mod+b toggle: Bar takes space (dock mode)
- Adaptive bar height detection
- Minimal CPU usage (~0.1%)
- Auto-recovery from errors
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

# Configuration
SHOW_THRESHOLD = int(os.getenv("AUTO_BAR_SHOW_THRESHOLD", "5"))  # Trigger distance from top
POLL_INTERVAL = float(os.getenv("AUTO_BAR_POLL_INTERVAL", "0.1"))
DEBOUNCE = float(os.getenv("AUTO_BAR_DEBOUNCE", "0.08"))
LOGGING = bool(os.getenv("AUTO_BAR_LOG", ""))
BAR_PADDING = int(os.getenv("AUTO_BAR_PADDING", "5"))  # Extra pixels below bar before hiding

STATE_FILE = Path.home() / ".config/i3/auto_bar/.bar_state"
_last_change_time = 0.0


def log(msg: str) -> None:
    """Thread-safe logging to stderr."""
    if LOGGING:
        sys.stderr.write(f"[auto_bar] {msg}\n")
        sys.stderr.flush()


def i3_cmd(cmd: list[str], timeout: float = 1.0) -> bool:
    """Execute i3-msg command with error handling."""
    try:
        result = subprocess.run(
            ["i3-msg"] + cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        if result.returncode != 0:
            log(f"i3-msg error: {result.stderr.strip()}")
            return False
        return True
    except subprocess.TimeoutExpired:
        log("i3-msg timeout")
        return False
    except Exception as e:
        log(f"i3-msg exception: {e}")
        return False


def set_bar_overlay(visible: bool) -> bool:
    """Set bar visibility in overlay mode (no window resize)."""
    global _last_change_time
    state = "show" if visible else "hide"
    if i3_cmd(["bar", "hidden_state", state]):
        _last_change_time = time.time()
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
    """
    Get the actual bar height in pixels.
    Returns bar height or default 30px if detection fails.
    """
    try:
        # Try to get geometry from visible bar window
        result = subprocess.run(
            ["xdotool", "search", "--class", "i3bar", "getwindowgeometry"],
            capture_output=True,
            text=True,
            timeout=1.0
        )
        if result.returncode == 0:
            for line in result.stdout.splitlines():
                if "Geometry:" in line:
                    # Parse: "  Geometry: 1920x32"
                    geometry = line.split("Geometry:")[1].strip()
                    height = int(geometry.split("x")[1])
                    log(f"Detected bar height: {height}px")
                    return height
    except Exception as e:
        log(f"Bar height detection failed: {e}")
    
    # Fallback: Try to calculate from font size
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
            # Extract font size from strings like "pango:JetBrainsMono Nerd Font 14"
            if font:
                parts = font.split()
                for part in parts:
                    if part.isdigit():
                        font_size = int(part)
                        # Bar height is typically font_size * 2 + padding
                        estimated_height = font_size * 2 + 4
                        log(f"Estimated bar height from font: {estimated_height}px")
                        return estimated_height
    except Exception:
        pass
    
    # Default fallback
    default_height = 30
    log(f"Using default bar height: {default_height}px")
    return default_height


def get_mouse_y() -> Optional[int]:
    """Get mouse Y coordinate using Xlib (fast) or xdotool (fallback)."""
    # Try Xlib first (most efficient)
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
                    return int(line.split("=", 1)[1])
    except Exception:
        pass
    
    return None


def is_singleton() -> bool:
    """Ensure only one instance is running."""
    try:
        result = subprocess.run(
            ["pgrep", "-fc", "auto_bar_hover"],
            capture_output=True,
            text=True
        )
        count = int(result.stdout.strip()) if result.stdout.strip() else 0
        return count <= 1
    except Exception:
        return True  # If we can't check, allow running


def main() -> int:
    """Main event loop with modern auto-hide behavior."""
    if not is_singleton():
        log("Another instance already running")
        return 0
    
    # Detect bar height for accurate hide threshold
    bar_height = get_bar_height()
    hide_threshold = bar_height + BAR_PADDING
    
    log(f"Starting i3bar auto-hover (modern behavior)")
    log(f"Show threshold: {SHOW_THRESHOLD}px from top")
    log(f"Hide threshold: {hide_threshold}px (bar height: {bar_height}px + padding: {BAR_PADDING}px)")
    log(f"Poll interval: {POLL_INTERVAL}s, Debounce: {DEBOUNCE}s")
    
    # Initialize: hide bar in overlay mode
    set_bar_overlay(False)
    bar_visible = False
    last_change = 0.0
    
    try:
        while True:
            try:
                now = time.time()
                
                # Skip hover logic if bar is in dock/invisible mode (user toggled with Mod+b)
                mode = get_bar_mode()
                if mode in ("dock", "invisible"):
                    if bar_visible:  # Reset state if we were tracking hover
                        bar_visible = False
                    time.sleep(POLL_INTERVAL)
                    continue
                
                y = get_mouse_y()
                
                if y is None:
                    time.sleep(POLL_INTERVAL)
                    continue
                
                # MODERN BEHAVIOR:
                # Show bar when mouse reaches top edge
                if y <= SHOW_THRESHOLD and not bar_visible and (now - last_change) > DEBOUNCE:
                    if set_bar_overlay(True):
                        bar_visible = True
                        last_change = now
                        log(f"Bar shown (mouse at y={y})")
                
                # Hide bar only when mouse leaves the bar area completely
                # (not just moving away from top edge)
                elif y > hide_threshold and bar_visible and (now - last_change) > DEBOUNCE:
                    if set_bar_overlay(False):
                        bar_visible = False
                        last_change = now
                        log(f"Bar hidden (mouse at y={y}, below threshold {hide_threshold})")
                
                time.sleep(POLL_INTERVAL)
                
            except KeyboardInterrupt:
                raise
            except Exception as e:
                log(f"Loop error: {e}")
                time.sleep(POLL_INTERVAL * 2)  # Back off on errors
                
    except KeyboardInterrupt:
        log("Shutting down")
        return 0


if __name__ == "__main__":
    sys.exit(main())
