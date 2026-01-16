# Phase 04: User Experience Improvements

## Context Links
- Research: [Ubuntu Fcitx5 Integration - Section 5](../reports/researcher-2026-01-16-1552-ubuntu-fcitx5-integration.md)
- Current: `docs/install-linux.md`

## Overview
**Priority:** P2
**Status:** Pending
**Effort:** 2h

Enhance first-time setup experience with diagnostics, clear instructions, and visual feedback.

## Key Insights

1. **First Impressions Matter:** Users expect one-command install
2. **Troubleshooting is Common:** IM setup often fails silently
3. **Visual Feedback:** GNOME users need to see what's happening
4. **Documentation:** Clear, step-by-step guides

## Requirements

### Functional
- Diagnostic script to check system configuration
- Visual setup wizard (optional GUI)
- Clear error messages with solutions
- "Quick Fix" command for common issues
- Updated documentation with screenshots

### Non-functional
- Non-intrusive - don't spam user
- Fast feedback (<1s for diagnostics)
- Works on both X11 and Wayland

## Architecture

```
gonhanh-cli (gn command)
├── status       # Show current config
├── diagnose     # Run system checks
├── fix-env      # Auto-fix environment vars
├── fix-gnome    # Install KIMPanel
└── help         # Show all commands
```

## Related Code Files

### Files to Modify
- `platforms/linux/scripts/gonhanh-cli.sh` - Enhance CLI with diagnostics

### Files to Create
- `platforms/linux/scripts/diagnose.sh` - System diagnostic script
- `docs/troubleshooting-ubuntu.md` - Ubuntu-specific troubleshooting guide

## Implementation Steps

### 1. Enhanced CLI Tool (`gonhanh-cli.sh`)

Update existing CLI with new commands:

```bash
#!/bin/bash
# Gõ Nhanh CLI tool for Ubuntu

cmd_status() {
    echo "=== Gõ Nhanh Status ==="
    echo "Version: $(cat ~/.config/gonhanh/version 2>/dev/null || echo 'Unknown')"
    echo "Method: $(cat ~/.config/gonhanh/method 2>/dev/null || echo 'Telex')"

    # Check Fcitx5
    if pgrep fcitx5 > /dev/null; then
        echo "✓ Fcitx5 is running"
    else
        echo "✗ Fcitx5 is not running"
    fi

    # Check environment
    if [ -f "$HOME/.config/environment.d/90-gonhanh.conf" ]; then
        echo "✓ Environment configured"
    else
        echo "⚠ Environment not configured (run: gn fix-env)"
    fi

    # Check desktop
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] && [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        if check_kimpanel; then
            echo "✓ KIMPanel installed"
        else
            echo "⚠ KIMPanel missing (run: gn fix-gnome)"
        fi
    fi
}

cmd_diagnose() {
    echo "=== Gõ Nhanh Diagnostics ==="

    # 1. Check Fcitx5 installation
    if command -v fcitx5 &> /dev/null; then
        echo "✓ Fcitx5 installed: $(fcitx5 --version | head -1)"
    else
        echo "✗ Fcitx5 not installed (run: sudo apt install fcitx5)"
        return 1
    fi

    # 2. Check addon
    if [ -f "$HOME/.local/lib/fcitx5/gonhanh.so" ]; then
        echo "✓ Gõ Nhanh addon installed"
    else
        echo "✗ Addon not found (run: sudo apt install fcitx5-gonhanh)"
        return 1
    fi

    # 3. Check environment variables
    local env_vars=("GTK_IM_MODULE" "QT_IM_MODULE" "XMODIFIERS")
    local all_set=true
    for var in "${env_vars[@]}"; do
        if [ "${!var}" = "fcitx" ]; then
            echo "✓ $var=fcitx"
        else
            echo "✗ $var not set (run: gn fix-env)"
            all_set=false
        fi
    done

    # 4. Check Fcitx5 config
    if fcitx5-remote &> /dev/null; then
        echo "✓ Fcitx5 is responsive"
    else
        echo "⚠ Fcitx5 not responding (run: fcitx5 -r)"
    fi

    # 5. Desktop-specific checks
    if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
        echo "Desktop: GNOME ($XDG_SESSION_TYPE)"
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
            if check_kimpanel; then
                echo "✓ KIMPanel extension installed"
            else
                echo "✗ KIMPanel missing (run: gn fix-gnome)"
            fi
        fi
    fi

    echo ""
    echo "=== Recommendations ==="
    [ "$all_set" = false ] && echo "• Run: gn fix-env"
    ! pgrep fcitx5 > /dev/null && echo "• Log out and log in again"

    return 0
}

cmd_fix_env() {
    echo "Fixing environment variables..."
    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/90-gonhanh.conf" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF
    echo "✓ Environment configured"
    echo "  Please log out and log in for changes to take effect"
}

cmd_fix_gnome() {
    if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
        echo "Not running GNOME, skipping"
        return 0
    fi

    if check_kimpanel; then
        echo "✓ KIMPanel already installed"
        return 0
    fi

    echo "Installing KIMPanel extension..."
    sudo apt update && sudo apt install -y gnome-shell-extension-kimpanel

    echo "✓ KIMPanel installed"
    echo "  Enable it: Extensions app → Input Method Panel → ON"
}

# Main command dispatcher
case "$1" in
    status)    cmd_status ;;
    diagnose)  cmd_diagnose ;;
    fix-env)   cmd_fix_env ;;
    fix-gnome) cmd_fix_gnome ;;
    *)         cmd_help ;;
esac
```

### 2. Create Troubleshooting Guide

File: `docs/troubleshooting-ubuntu.md`

```markdown
# Troubleshooting Gõ Nhanh on Ubuntu

## Quick Diagnostics

Run: `gn diagnose`

This will check:
- Fcitx5 installation
- Gõ Nhanh addon
- Environment variables
- Desktop environment compatibility

## Common Issues

### 1. Can't type Vietnamese

**Check:** Run `gn status`

**Fix:**
bash
gn fix-env
# Log out and log in
fcitx5-configtool  # Add Gõ Nhanh to input methods


### 2. Candidate window not showing (GNOME)

**Cause:** KIMPanel extension missing

**Fix:**
bash
gn fix-gnome
# Enable in Extensions app


### 3. Works in Terminal but not Chrome/VS Code

**Cause:** Electron apps need special flags

**Fix:** Create `~/.config/electron-flags.conf`:


--enable-features=UseOzonePlatform
--ozone-platform=wayland
--enable-wayland-ime

Restart apps.

[... more issues ...]
```

### 3. Visual Feedback in Terminal

Add colored output for better UX:

```bash
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
```

## Todo List

- [ ] Enhance gonhanh-cli.sh with new commands
- [ ] Add colored output for better visibility
- [ ] Create comprehensive troubleshooting guide
- [ ] Add screenshots to documentation
- [ ] Create "Quick Start" video/GIF
- [ ] Test diagnostic script on clean Ubuntu install
- [ ] Add desktop notification on successful setup
- [ ] Create FAQ section in README

## Success Criteria

- [ ] `gn diagnose` detects all common issues
- [ ] `gn fix-*` commands resolve issues automatically
- [ ] Troubleshooting guide covers top 10 issues
- [ ] Clear visual feedback (colors, emojis)
- [ ] Works on both X11 and Wayland

## Risk Assessment

**Risk:** Diagnostic false positives/negatives
**Mitigation:** Test on multiple Ubuntu versions, update based on user feedback

**Risk:** Auto-fix breaks user's custom setup
**Mitigation:** Always backup before modifying, make fixes optional

## Security Considerations

- Don't require sudo for diagnostics
- Only request sudo when absolutely necessary (package install)
- Validate all file paths before modification

## Next Steps

After completion:
- Gather user feedback on setup experience
- Update FAQ based on common support requests
- Proceed to Phase 05: Testing & Validation
