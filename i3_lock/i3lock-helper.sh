#!/usr/bin/env bash
# i3lock-fancy Helper Script
# Quick access to different lock screen modes

show_help() {
    cat << EOF
i3lock-fancy Helper Script
==========================

Usage: $(basename "$0") [mode]

Available modes:
  fast      - Fast pixelated lock (default)
  blur      - Slower blur effect lock
  grey      - Greyscale lock
  minimal   - Minimize windows then lock
  test      - Test all components without locking
  help      - Show this help message

Examples:
  $(basename "$0")          # Fast lock (default)
  $(basename "$0") fast     # Fast pixelated lock
  $(basename "$0") blur     # Beautiful blur effect
  $(basename "$0") grey     # Greyscale effect
  $(basename "$0") minimal  # Minimize windows first

Current lock keybinding in i3: Mod+Escape
EOF
}

test_components() {
    echo "Testing i3lock-fancy components..."
    echo ""
    
    # Test i3lock-color
    if command -v i3lock >/dev/null 2>&1; then
        echo "✓ i3lock-color: $(i3lock --version 2>&1 | head -1)"
    else
        echo "✗ i3lock-color not found"
        return 1
    fi
    
    # Test ImageMagick
    if command -v convert >/dev/null 2>&1; then
        echo "✓ ImageMagick: $(convert --version | head -1 | cut -d' ' -f3)"
    else
        echo "✗ ImageMagick not found"
        return 1
    fi
    
    # Test screenshot utilities
    if command -v scrot >/dev/null 2>&1; then
        echo "✓ scrot: $(scrot --version 2>&1 | head -1)"
    elif command -v maim >/dev/null 2>&1; then
        echo "✓ maim installed"
    else
        echo "✗ No screenshot utility found"
        return 1
    fi
    
    # Test i3lock-fancy
    if command -v i3lock-fancy >/dev/null 2>&1; then
        echo "✓ i3lock-fancy: $(which i3lock-fancy)"
    else
        echo "✗ i3lock-fancy not found"
        return 1
    fi
    
    # Test icons
    if [ -d "/usr/share/i3lock-fancy/icons" ]; then
        icon_count=$(ls -1 /usr/share/i3lock-fancy/icons/ | wc -l)
        echo "✓ Icons: $icon_count files in /usr/share/i3lock-fancy/icons/"
    else
        echo "✗ Icons directory not found"
        return 1
    fi
    
    echo ""
    echo "All components are working correctly!"
}

mode="${1:-fast}"

case "$mode" in
    fast|default)
        echo "Locking screen with fast pixelate effect..."
        i3lock-fancy -p -- scrot -z
        ;;
    blur)
        echo "Locking screen with blur effect (slower)..."
        i3lock-fancy -- scrot -z
        ;;
    grey|greyscale)
        echo "Locking screen with greyscale effect..."
        i3lock-fancy -g -p -- scrot -z
        ;;
    minimal|minimize)
        echo "Minimizing windows and locking screen..."
        i3lock-fancy -d -p -- scrot -z
        ;;
    test)
        test_components
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown mode: $mode"
        echo ""
        show_help
        exit 1
        ;;
esac
