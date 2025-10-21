# i3lock-fancy Setup Documentation

## Installation Summary

i3lock-fancy has been successfully installed and configured on your system!

### What was installed:

1. **i3lock-color** (v2.13.c.5) - Enhanced version of i3lock with color support
   - Location: `/usr/bin/i3lock`
   - Built from source: https://github.com/Raymo111/i3lock-color

2. **i3lock-fancy** - Blur/pixelate lock screen script
   - Location: `/usr/bin/i3lock-fancy`
   - Icons: `/usr/share/i3lock-fancy/icons/`
   - Source: https://github.com/meskarune/i3lock-fancy

3. **Dependencies installed:**
   - imagemagick (image processing)
   - scrot (screenshot utility)
   - maim (alternative screenshot utility)
   - wmctrl (window management)
   - libcairo2-dev (graphics library)
   - Various build dependencies for i3lock-color

## Usage

### Keyboard Shortcuts

The following keyboard shortcut has been configured in your i3 config:

- **Mod+Escape**: Lock screen with i3lock-fancy (pixelated blur effect)

### Manual Commands

You can also run i3lock-fancy manually from a terminal:

```bash
# Basic lock with blur effect
i3lock-fancy

# Lock with pixelate effect (faster)
i3lock-fancy -p

# Lock with greyscale
i3lock-fancy -g

# Lock and minimize all windows first
i3lock-fancy -d

# Lock with custom text
i3lock-fancy -t "Custom Lock Text"

# Use scrot for faster screenshots (recommended)
i3lock-fancy -p -- scrot -z

# Combine options (pixelate + greyscale + minimize windows + scrot)
i3lock-fancy -d -g -p -- scrot -z
```

### Available Options

- `-h, --help` - Show help menu
- `-d, --desktop` - Minimize all windows before locking (requires wmctrl)
- `-g, --greyscale` - Set background to greyscale instead of color
- `-p, --pixelate` - Pixelate the background instead of blur (faster)
- `-f <font>` - Set a custom font
- `-t <text>` - Set a custom text prompt
- `-l, --listfonts` - List available fonts
- `-n, --nofork` - Do not fork i3lock after starting
- `--` - Specify screenshot command (use `scrot -z` or `maim` for better performance)

## Integration

### i3 Configuration

Your i3 config has been updated at: `~/.config/i3/config`

Key changes:
1. Lock screen binding updated to use i3lock-fancy
2. xss-lock configured to use i3lock-fancy on suspend

### Auto-lock on Suspend

The system will automatically lock the screen when:
- You suspend your computer
- The system goes to sleep
- You manually run `loginctl lock-session`

This is handled by xss-lock which was already configured in your system.

## Testing

A comprehensive test was performed and all components passed:

✓ i3lock-color installed and working
✓ ImageMagick installed and working
✓ scrot (screenshot utility) working
✓ i3lock-fancy script installed
✓ Icons properly installed
✓ Screenshot capture working
✓ Image processing (blur/pixelate) working

## Performance Tips

1. **Use pixelate instead of blur**: The `-p` flag is faster
   ```bash
   i3lock-fancy -p
   ```

2. **Use scrot for screenshots**: Faster than the default ImageMagick import
   ```bash
   i3lock-fancy -p -- scrot -z
   ```

3. **Optimal configuration** (already set in your i3 config):
   ```bash
   i3lock-fancy -p -- scrot -z
   ```

## Troubleshooting

### Lock screen doesn't work
1. Check if i3lock-color is installed: `i3lock --version`
2. Check if i3lock-fancy is installed: `which i3lock-fancy`
3. Run test script: `/tmp/test-i3lock-fancy.sh` (if it still exists)

### Screen doesn't blur properly
- Try using pixelate mode instead: `i3lock-fancy -p`
- Ensure ImageMagick is installed: `convert --version`

### Screenshot fails
- Check if scrot is working: `scrot /tmp/test.png`
- Alternative: use maim instead: `i3lock-fancy -p -- maim`

### Icons not showing
- Verify icons exist: `ls /usr/share/i3lock-fancy/icons/`
- Reinstall if needed: `cd /tmp/i3lock-fancy && sudo make install`

## Customization

### Change Lock Screen Text

Edit your i3 config to add custom text:
```
bindsym $mod+Escape exec "i3lock-fancy -t 'Welcome Back!' -p -- scrot -z"
```

### Use Different Screenshot Tool

If you prefer maim over scrot:
```
bindsym $mod+Escape exec "i3lock-fancy -p -- maim"
```

### Enable Window Minimization

To minimize all windows before locking:
```
bindsym $mod+Escape exec "i3lock-fancy -d -p -- scrot -z"
```

## System Service (Optional)

If you want to set up auto-lock after inactivity, you can use xautolock:

```bash
# Install xautolock
sudo apt-get install xautolock

# Add to i3 config for 5-minute auto-lock:
exec --no-startup-id xautolock -time 5 -locker "i3lock-fancy -p -- scrot -z" -detectsleep
```

## Files Modified

- `/home/pragun/.config/i3/config` - Updated lock screen keybinding and xss-lock configuration

## Additional Resources

- i3lock-color: https://github.com/Raymo111/i3lock-color
- i3lock-fancy: https://github.com/meskarune/i3lock-fancy
- i3lock-fancy website: http://meskarune.github.io/i3lock-fancy/

## Version Information

Installation Date: October 21, 2025
- i3lock-color: 2.13.c.5-6-g4f60040
- ImageMagick: 6.9.11-60 Q16
- scrot: 1.7
- System: Ubuntu 22.04.5 LTS

---

**Setup completed successfully!** Press Mod+Escape to test your new fancy lock screen.
