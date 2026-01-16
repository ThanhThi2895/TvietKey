# Phase 02: GNOME/Wayland Compatibility

## Context Links
- Research: [Ubuntu Fcitx5 Integration - Section 3.A](../reports/researcher-2026-01-16-1552-ubuntu-fcitx5-integration.md)
- Issue: GNOME doesn't support Wayland `input-method-v2` protocol for popups

## Overview
**Priority:** P1
**Status:** Pending
**Effort:** 3h

Fix candidate window positioning on Ubuntu GNOME/Wayland by detecting and installing KIMPanel extension.

## Key Insights

1. **Root Cause:** GNOME Shell lacks native IME panel protocol support
2. **Solution:** KIMPanel extension bridges this gap
3. **Package:** `gnome-shell-extension-kimpanel` (Ubuntu repos)
4. **Alternative:** Detect and warn users to install manually

## Requirements

### Functional
- Detect if running on GNOME Wayland
- Check if KIMPanel extension installed
- Auto-install KIMPanel (if sudo available and user confirms)
- Provide manual installation instructions if auto-install fails
- Verify extension enabled after install

### Non-functional
- Non-intrusive - don't force install without permission
- Clear messaging about why KIMPanel needed
- Graceful degradation if user declines

## Architecture

```
install.sh
  ├─> Detect desktop environment
  ├─> If GNOME + Wayland detected
  │   ├─> Check KIMPanel installed
  │   ├─> If missing:
  │   │   ├─> Offer to install
  │   │   └─> Show manual instructions
  │   └─> Enable extension
  └─> Continue installation
```

## Related Code Files

### Files to Modify
- `platforms/linux/scripts/install.sh` - Add GNOME detection + KIMPanel setup

### Files to Create
- None (logic added to install.sh)

## Implementation Steps

1. **Desktop environment detection**
   ```bash
   detect_desktop() {
       if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] && [ "$XDG_SESSION_TYPE" = "wayland" ]; then
           return 0  # GNOME Wayland
       fi
       return 1
   }
   ```

2. **KIMPanel detection**
   ```bash
   check_kimpanel() {
       # Method 1: Check if extension installed
       if [ -d "$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
          [ -d "/usr/share/gnome-shell/extensions/kimpanel@kde.org" ]; then
           return 0
       fi
       # Method 2: Check package
       dpkg -l | grep -q gnome-shell-extension-kimpanel && return 0
       return 1
   }
   ```

3. **Auto-install KIMPanel**
   ```bash
   install_kimpanel() {
       echo "⚠️  GNOME/Wayland detected. KIMPanel required for proper candidate window positioning."
       read -p "Install gnome-shell-extension-kimpanel? [Y/n] " -n 1 -r
       echo
       if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
           sudo apt update && sudo apt install -y gnome-shell-extension-kimpanel
           echo "✓ KIMPanel installed. Please enable it in Extensions app."
       fi
   }
   ```

4. **Enable extension (if possible)**
   - Use `gnome-extensions enable kimpanel@kde.org` if available
   - Otherwise, guide user to Extensions app

5. **Electron/Chromium app detection**
   - Add note about `--enable-wayland-ime` flag for VS Code, Chrome, etc.
   - Optionally create desktop file overrides

## Todo List

- [ ] Implement `detect_desktop()` function
- [ ] Implement `check_kimpanel()` function
- [ ] Add KIMPanel installation prompt
- [ ] Add extension enable logic
- [ ] Test on GNOME Wayland (Ubuntu 24.04)
- [ ] Test on GNOME X11 (should skip KIMPanel check)
- [ ] Add Electron app notes to docs
- [ ] Update troubleshooting guide

## Success Criteria

- Auto-detects GNOME Wayland environment
- Prompts to install KIMPanel if missing
- Provides clear manual instructions
- Works without KIMPanel on X11
- Candidate window positioned correctly after setup

## Risk Assessment

**Risk:** User doesn't enable extension after install
**Mitigation:** Clear post-install message, link to Extensions app

**Risk:** KIMPanel breaks on GNOME update
**Mitigation:** Document alternative: switch to X11 session

**Risk:** Sudo not available
**Mitigation:** Fallback to manual instructions

## Security Considerations

- Request sudo only if user confirms
- Don't modify GNOME Shell directly
- Only install from Ubuntu official repos

## Electron Apps - Additional Notes

Common apps requiring `--enable-wayland-ime`:
- VS Code
- Chrome/Chromium
- Discord
- Slack

**Fix:** Create `~/.config/electron-flags.conf`:
```
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--enable-wayland-ime
```

**Note:** Many apps in 2026 have this enabled by default, but user may need to verify.

## Next Steps

After completion:
- Proceed to Phase 03: Debian Package Creation
- Test candidate window in various apps
- Document known app-specific workarounds
