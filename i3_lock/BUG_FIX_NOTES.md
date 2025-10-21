# i3lock-fancy Bug Fix - October 21, 2025

## Problem Identified

The original i3lock-fancy script had a bug when using custom screenshot tools like `scrot`. The issue was:

1. The script creates a temporary file using `mktemp --suffix=.png`
2. `mktemp` creates the file with restrictive permissions (600)
3. When using `scrot` (or other screenshot tools), they cannot overwrite the pre-existing file
4. This results in an empty PNG file and causes the error:
   ```
   convert-im6.q16: improper image header `/tmp/tmp.XXXXXX.png' @ error/png.c/ReadPNGImage/4107.
   ```

## Solution Applied

Added a fix to remove the pre-created temporary file when using custom screenshot commands:

```bash
if "$shot_custom" && [[ $# -gt 0 ]]; then
    shot=("$@");
    # FIX: Remove the pre-created file for tools that can't overwrite
    rm -f "$image"
fi
```

This allows `scrot`, `maim`, and other screenshot tools to create their own files without permission issues.

## Changes Made

1. **Backed up original:** `/usr/bin/i3lock-fancy` → `/usr/bin/i3lock-fancy.backup`
2. **Installed fixed version:** Applied patch to `/usr/bin/i3lock-fancy`
3. **Tested all methods:**
   - ✓ Default method (import) - Working
   - ✓ Custom scrot - Working  
   - ✓ Custom scrot -z - Working
   - ✓ Greyscale mode - Working

## Verification

All lock screen methods now work correctly:

```bash
# Default (using import)
i3lock-fancy -p

# With scrot
i3lock-fancy -p -- scrot

# With scrot compressed
i3lock-fancy -p -- scrot -z

# With greyscale
i3lock-fancy -g -p

# Keyboard shortcut
Mod+Escape  # (works!)
```

## Files Modified

- `/usr/bin/i3lock-fancy` - Fixed script with patch applied
- `/usr/bin/i3lock-fancy.backup` - Original backup

## Status

✅ **BUG FIXED** - All lock screen methods working perfectly!

---

**Fix Applied:** October 21, 2025  
**Issue:** mktemp file permission conflict with scrot  
**Solution:** Remove pre-created file when using custom screenshot tools
