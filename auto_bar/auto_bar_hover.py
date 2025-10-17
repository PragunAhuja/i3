#!/usr/bin/env python3
"""
Auto-show/hide i3bar when the mouse is at the top of the screen.

Uses XQueryPointer polling with python-xlib for minimal CPU usage (~0.1% typical).
Falls back to xdotool if python-xlib is not available.

STATE MANAGEMENT:
- bar_is_pinned: Tracks whether user explicitly toggled bar with Mod+b
- When pinned=True: Bar stays visible, mouse events are ignored
- When pinned=False: Bar responds to mouse hover (auto-show/hide)

Toggle logging: AUTO_BAR_LOG=1
Adjust threshold: AUTO_BAR_THRESHOLD=10 (pixels from top)
"""

from __future__ import annotations
import os
import subprocess
import time
import sys
from pathlib import Path

# Config
THRESHOLD = int(os.getenv("AUTO_BAR_THRESHOLD", "5"))
POLL_INTERVAL = float(os.getenv("AUTO_BAR_POLL_INTERVAL", "0.1"))
DEBOUNCE = float(os.getenv("AUTO_BAR_DEBOUNCE", "0.08"))
LOGGING = bool(os.getenv("AUTO_BAR_LOG"))

# State file to persist pinned state across script restarts
STATE_FILE = Path.home() / ".config/i3/auto_bar/.bar_state"


def log(msg: str) -> None:
    if LOGGING:
        sys.stderr.write(f"[auto_bar_hover] {msg}\n")
        sys.stderr.flush()


def load_pinned_state() -> bool:
    """Load the persisted pinned state from disk."""
    try:
        if STATE_FILE.exists():
            return STATE_FILE.read_text().strip() == "pinned"
    except Exception as e:
        log(f"Failed to load state: {e}")
    return False


def save_pinned_state(is_pinned: bool) -> None:
    """Save the pinned state to disk for persistence."""
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text("pinned" if is_pinned else "unpinned")
    except Exception as e:
        log(f"Failed to save state: {e}")


def get_current_bar_mode() -> str | None:
    """Query i3 for the current bar mode (invisible, visible, hide, or dock)."""
    try:
        result = subprocess.run(
            ["i3-msg", "-t", "get_bar_config", "bar-0"],
            capture_output=True,
            text=True,
            timeout=1.0
        )
        if result.returncode == 0:
            import json
            data = json.loads(result.stdout)
            return data.get("mode")
    except Exception as e:
        log(f"Failed to get bar mode: {e}")
    return None


def is_bar_manually_toggled() -> tuple[bool, str | None]:
    """
    Detect if the bar was manually toggled by checking current mode.
    Returns: (is_pinned, current_mode)
    
    Logic: If current mode changed to dock/hide (space-taking modes),
    user must have pressed Mod+b. Invisible/visible are hover modes.
    """
    current_mode = get_current_bar_mode()
    if current_mode is None:
        return load_pinned_state(), current_mode
    
    stored_pinned = load_pinned_state()
    
    # If we just changed it (<1 sec ago), don't interpret as user toggle
    if time.time() - _last_script_change < 1.0:
        return stored_pinned, current_mode
    
    # Dock/hide modes = user pressed Mod+b (space-taking modes)
    # Invisible/visible = script hover control (overlay modes)
    if current_mode == "dock" and not stored_pinned:
        log("Detected manual toggle to dock (Mod+b pressed - bar takes space)")
        save_pinned_state(True)
        return True, current_mode
    elif current_mode == "hide" and stored_pinned:
        log("Detected manual toggle to hide (Mod+b pressed)")
        save_pinned_state(False)
        return False, current_mode
    
    return stored_pinned, current_mode


def set_bar_visibility(visible: bool, overlay: bool = True) -> bool:
    """
    Set i3bar visibility.
    
    overlay=True: Toggle hidden_state (bar overlays, no window resize)
    overlay=False: Set mode dock/hide (bar takes space, windows resize)
    """
    try:
        if overlay:
            # For hover: use hidden_state toggle (bar in 'hide' mode overlays when shown)
            cmd = ["i3-msg", "bar", "hidden_state", "show" if visible else "hide"]
            state = "visible (overlay)" if visible else "hidden (overlay)"
        else:
            # For Mod+b: use mode dock/hide (bar takes window space)
            cmd = ["i3-msg", "bar", "mode", "dock" if visible else "hide"]
            state = "dock (takes space)" if visible else "hidden (takes space)"
        
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=1.0)
        if r.returncode != 0:
            log(f"i3-msg failed: {r.stderr.strip()}")
            return False
        log(f"Bar -> {state}")
        # Mark timestamp of our last change to distinguish from user toggles
        global _last_script_change
        _last_script_change = time.time()
        return True
    except Exception as e:
        log(f"set_bar_visibility error: {e}")
        return False

# Global to track when we last changed the bar mode
_last_script_change = 0.0


def run_xlib_polling() -> int:
    """Poll mouse position using Xlib XQueryPointer - minimal CPU."""
    try:
        from Xlib import display
    except ImportError as e:
        log(f"python-xlib not available: {e}")
        return 2

    try:
        disp = display.Display()
        root = disp.screen().root
    except Exception as e:
        sys.stderr.write(f"Failed to open X display: {e}\n")
        return 2

    # STATE MANAGEMENT: Initialize from saved state
    bar_is_pinned = load_pinned_state()
    last_change = 0.0
    last_state_check = time.time()

    # Initialize bar based on pinned state
    if not bar_is_pinned:
        set_bar_visibility(False, overlay=True)  # Hover mode: overlay, no window resize
        bar_visible = False
        log(f"Starting in UNPINNED mode - auto show/hide (overlay)")
    else:
        set_bar_visibility(True, overlay=False)  # Pinned mode: takes space, windows resize
        bar_visible = True
        log(f"Starting in PINNED mode - bar takes space")
    
    log(f"Xlib polling loop (interval={POLL_INTERVAL}s, threshold={THRESHOLD}px)")

    try:
        while True:
            try:
                now = time.time()
                
                # Periodically check if user manually toggled with Mod+b (every 2 seconds)
                # But skip the first few seconds to avoid false detections during startup
                if now - last_state_check > 2.0 and now > 3.0:
                    old_pinned = bar_is_pinned
                    bar_is_pinned, current_mode = is_bar_manually_toggled()
                    if bar_is_pinned != old_pinned:
                        log(f"State changed: pinned={bar_is_pinned}")
                    last_state_check = now
                    if current_mode:
                        bar_visible = (current_mode == "dock")
                
                # CRITICAL: Only process mouse events if bar is NOT pinned
                if not bar_is_pinned:
                    # Query pointer position (lightweight syscall)
                    pointer = root.query_pointer()
                    y = pointer.root_y
                    
                    if LOGGING and bar_visible != (y <= THRESHOLD):
                        log(f"Mouse Y={y} (unpinned - overlay mode)")
                    
                    # Show bar when mouse at top (overlay mode - no window resize)
                    if y <= THRESHOLD and not bar_visible and (now - last_change) > DEBOUNCE:
                        if set_bar_visibility(True, overlay=True):  # Overlay: show bar, no space
                            bar_visible = True
                            last_change = now
                    
                    # Hide bar when mouse moves away (overlay mode)
                    elif y > THRESHOLD and bar_visible and (now - last_change) > DEBOUNCE:
                        if set_bar_visibility(False, overlay=True):  # Overlay: hide bar, no space
                            bar_visible = False
                            last_change = now
                else:
                    # Bar is pinned - ensure it stays in dock mode (takes space)
                    if not bar_visible:
                        set_bar_visibility(True, overlay=False)
                        bar_visible = True
                        log("Enforcing pinned state")
                
                time.sleep(POLL_INTERVAL)
                
            except Exception as e:
                log(f"Query error: {e}")
                time.sleep(POLL_INTERVAL)
                
    except KeyboardInterrupt:
        log("Exiting on interrupt")
        return 0


def run_xdotool_fallback() -> int:
    """Fallback using xdotool subprocess calls with state management."""
    import shutil
    
    if shutil.which("xdotool") is None:
        sys.stderr.write("ERROR: xdotool not found. Install: sudo apt install xdotool\n")
        return 2

    # STATE MANAGEMENT: Track pinned state for fallback mode too
    bar_is_pinned, current_mode = is_bar_manually_toggled()
    bar_visible = (current_mode in ["dock", "visible"]) if current_mode else False
    last_change = 0.0
    last_state_check = 0.0
    
    if not bar_is_pinned:
        set_bar_visibility(False, overlay=True)  # Overlay mode
        bar_visible = False
    
    log(f"Using xdotool fallback (interval={POLL_INTERVAL}s, pinned={bar_is_pinned})")

    def get_y() -> int | None:
        try:
            r = subprocess.run(
                ["xdotool", "getmouselocation", "--shell"],
                capture_output=True,
                text=True,
                timeout=0.5
            )
            if r.returncode != 0:
                return None
            for line in r.stdout.splitlines():
                if line.startswith("Y="):
                    return int(line.split("=", 1)[1])
        except Exception:
            pass
        return None

    try:
        while True:
            now = time.time()
            
            # Check for manual toggle state changes
            if now - last_state_check > 2.0:
                bar_is_pinned, current_mode = is_bar_manually_toggled()
                last_state_check = now
                if current_mode:
                    bar_visible = (current_mode == "dock")
            
            # Only process mouse events if unpinned
            if not bar_is_pinned:
                y = get_y()
                if y is None:
                    time.sleep(POLL_INTERVAL)
                    continue
                
                if y <= THRESHOLD and not bar_visible and (now - last_change) > DEBOUNCE:
                    if set_bar_visibility(True, overlay=True):  # Overlay mode
                        bar_visible = True
                        last_change = now
                elif y > THRESHOLD and bar_visible and (now - last_change) > DEBOUNCE:
                    if set_bar_visibility(False, overlay=True):  # Overlay mode
                        bar_visible = False
                        last_change = now
            else:
                # Enforce pinned state - dock mode (takes space)
                if not bar_visible:
                    set_bar_visibility(True, overlay=False)
                    bar_visible = True
            
            time.sleep(POLL_INTERVAL)
            
    except KeyboardInterrupt:
        log("Exiting on interrupt")
        return 0


def main() -> int:
    # Check if another instance is already running
    import subprocess
    try:
        result = subprocess.run(
            ["pgrep", "-f", "auto_bar_hover.py"],
            capture_output=True,
            text=True
        )
        pids = [int(p) for p in result.stdout.strip().split('\n') if p]
        my_pid = os.getpid()
        other_pids = [p for p in pids if p != my_pid]
        
        if other_pids:
            log(f"Another instance already running (PIDs: {other_pids}), exiting")
            return 0
    except Exception as e:
        log(f"Could not check for other instances: {e}")
    
    # Prefer Xlib (native, efficient)
    try:
        import Xlib
        return run_xlib_polling()
    except ImportError:
        log("Xlib not available, using xdotool")
        return run_xdotool_fallback()


if __name__ == '__main__':
    raise SystemExit(main())

