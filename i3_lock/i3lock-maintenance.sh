#!/usr/bin/env bash
# i3lock-fancy Maintenance and Troubleshooting Script

show_menu() {
    clear
    echo "=========================================="
    echo "  i3lock-fancy Maintenance Menu"
    echo "=========================================="
    echo ""
    echo "1. Test lock screen (without locking)"
    echo "2. Check installation status"
    echo "3. View current configuration"
    echo "4. Test different lock modes"
    echo "5. Troubleshooting information"
    echo "6. Reinstall i3lock-fancy"
    echo "7. View documentation"
    echo "8. Exit"
    echo ""
    read -p "Select an option (1-8): " choice
    echo ""
    
    case $choice in
        1) test_lock ;;
        2) check_status ;;
        3) view_config ;;
        4) test_modes ;;
        5) troubleshoot ;;
        6) reinstall ;;
        7) view_docs ;;
        8) exit 0 ;;
        *) echo "Invalid option"; sleep 2; show_menu ;;
    esac
}

test_lock() {
    echo "Testing lock screen components..."
    echo ""
    
    # Create a test image
    TEST_DIR="/tmp/i3lock-test-$$"
    mkdir -p "$TEST_DIR"
    
    echo "1. Capturing screenshot..."
    if scrot "$TEST_DIR/screenshot.png" 2>/dev/null; then
        echo "   ✓ Screenshot captured"
    else
        echo "   ✗ Screenshot failed"
        read -p "Press Enter to continue..."
        show_menu
        return
    fi
    
    echo "2. Applying blur effect..."
    if convert "$TEST_DIR/screenshot.png" -filter Gaussian -resize 20% -resize 500% "$TEST_DIR/blurred.png" 2>/dev/null; then
        echo "   ✓ Blur effect applied"
    else
        echo "   ✗ Blur effect failed"
    fi
    
    echo "3. Applying pixelate effect..."
    if convert "$TEST_DIR/screenshot.png" -scale 10% -scale 1000% "$TEST_DIR/pixelated.png" 2>/dev/null; then
        echo "   ✓ Pixelate effect applied"
    else
        echo "   ✗ Pixelate effect failed"
    fi
    
    echo ""
    echo "Test images created in: $TEST_DIR"
    echo "  - screenshot.png (original)"
    echo "  - blurred.png (blur effect)"
    echo "  - pixelated.png (pixelate effect)"
    echo ""
    echo "You can view these images to see how your lock screen will look."
    echo ""
    read -p "Press Enter to continue..."
    show_menu
}

check_status() {
    echo "Installation Status:"
    echo "===================="
    echo ""
    
    echo "i3lock-color:"
    if command -v i3lock >/dev/null 2>&1; then
        i3lock --version 2>&1 | head -1
    else
        echo "  ✗ Not installed"
    fi
    echo ""
    
    echo "i3lock-fancy:"
    if [ -x /usr/bin/i3lock-fancy ]; then
        echo "  ✓ Installed at /usr/bin/i3lock-fancy"
    else
        echo "  ✗ Not installed"
    fi
    echo ""
    
    echo "Icons:"
    if [ -d /usr/share/i3lock-fancy/icons ]; then
        count=$(ls -1 /usr/share/i3lock-fancy/icons/*.png 2>/dev/null | wc -l)
        echo "  ✓ $count icon files found"
    else
        echo "  ✗ Icons directory not found"
    fi
    echo ""
    
    echo "Dependencies:"
    echo "  ImageMagick: $(command -v convert >/dev/null && echo '✓' || echo '✗')"
    echo "  scrot:       $(command -v scrot >/dev/null && echo '✓' || echo '✗')"
    echo "  maim:        $(command -v maim >/dev/null && echo '✓' || echo '✗')"
    echo "  wmctrl:      $(command -v wmctrl >/dev/null && echo '✓' || echo '✗')"
    echo ""
    
    read -p "Press Enter to continue..."
    show_menu
}

view_config() {
    echo "Current i3 Configuration:"
    echo "========================="
    echo ""
    
    if [ -f ~/.config/i3/config ]; then
        echo "Lock screen bindings:"
        grep -A 2 "i3lock" ~/.config/i3/config | head -10
        echo ""
        echo "Full config: ~/.config/i3/config"
    else
        echo "✗ Config file not found"
    fi
    echo ""
    
    read -p "Press Enter to continue..."
    show_menu
}

test_modes() {
    echo "Test Different Lock Modes"
    echo "========================="
    echo ""
    echo "WARNING: These commands will actually lock your screen!"
    echo "You will need to enter your password to unlock."
    echo ""
    echo "1. Fast pixelate lock"
    echo "2. Blur effect lock"
    echo "3. Greyscale lock"
    echo "4. Minimize windows + lock"
    echo "5. Back to main menu"
    echo ""
    read -p "Select a mode to test (1-5): " mode
    
    case $mode in
        1)
            echo "Testing fast pixelate lock..."
            sleep 2
            i3lock-fancy -p -- scrot -z
            ;;
        2)
            echo "Testing blur effect lock..."
            sleep 2
            i3lock-fancy -- scrot -z
            ;;
        3)
            echo "Testing greyscale lock..."
            sleep 2
            i3lock-fancy -g -p -- scrot -z
            ;;
        4)
            echo "Testing minimize + lock..."
            sleep 2
            i3lock-fancy -d -p -- scrot -z
            ;;
        5)
            show_menu
            return
            ;;
        *)
            echo "Invalid option"
            sleep 2
            ;;
    esac
    
    show_menu
}

troubleshoot() {
    echo "Troubleshooting Information"
    echo "==========================="
    echo ""
    
    echo "System Information:"
    echo "-------------------"
    uname -a
    echo ""
    
    echo "Display:"
    echo "--------"
    echo "DISPLAY=$DISPLAY"
    echo ""
    
    echo "X Server:"
    echo "---------"
    ps aux | grep -i "x\|wayland" | grep -v grep | head -5
    echo ""
    
    echo "i3 Version:"
    echo "-----------"
    i3 --version
    echo ""
    
    echo "Recent Errors (if any):"
    echo "----------------------"
    journalctl --user -u graphical-session.target --no-pager -n 20 | grep -i "lock\|i3lock" || echo "No recent errors found"
    echo ""
    
    echo "Common Issues and Solutions:"
    echo "---------------------------"
    echo "1. Screen doesn't lock:"
    echo "   - Check if i3lock-color is installed: i3lock --version"
    echo "   - Try running manually: i3lock-fancy -p"
    echo ""
    echo "2. No blur/pixelate effect:"
    echo "   - Check ImageMagick: convert --version"
    echo "   - Try basic lock: i3lock -c 000000"
    echo ""
    echo "3. Screenshot fails:"
    echo "   - Check scrot: scrot /tmp/test.png"
    echo "   - Try alternative: i3lock-fancy -p -- maim"
    echo ""
    
    read -p "Press Enter to continue..."
    show_menu
}

reinstall() {
    echo "Reinstall i3lock-fancy"
    echo "======================"
    echo ""
    echo "This will reinstall i3lock-fancy from the GitHub repository."
    echo ""
    read -p "Do you want to continue? (y/n): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo ""
        echo "Reinstalling i3lock-fancy..."
        cd /tmp
        rm -rf i3lock-fancy
        git clone https://github.com/meskarune/i3lock-fancy.git
        cd i3lock-fancy
        sudo make install
        echo ""
        echo "✓ i3lock-fancy reinstalled"
        echo ""
    else
        echo "Reinstall cancelled"
    fi
    
    read -p "Press Enter to continue..."
    show_menu
}

view_docs() {
    echo "Documentation"
    echo "============="
    echo ""
    
    if [ -f ~/.config/i3/i3_lock/I3LOCK_FANCY_SETUP.md ]; then
        less ~/.config/i3/i3_lock/I3LOCK_FANCY_SETUP.md
    else
        echo "Documentation not found at ~/.config/i3/i3_lock/I3LOCK_FANCY_SETUP.md"
        echo ""
        echo "Quick Reference:"
        echo "---------------"
        i3lock-fancy --help
    fi
    echo ""
    
    read -p "Press Enter to continue..."
    show_menu
}

# Main entry point
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "i3lock-fancy Maintenance Script"
    echo ""
    echo "Usage: $(basename $0)"
    echo ""
    echo "Interactive menu for maintaining and troubleshooting i3lock-fancy."
    exit 0
fi

show_menu
