# Phase 01: Environment Integration

## Context Links
- Research: [Ubuntu Fcitx5 Integration](../reports/researcher-2026-01-16-1552-ubuntu-fcitx5-integration.md)
- Code: `platforms/linux/scripts/install.sh`

## Overview
**Priority:** P1
**Status:** Pending
**Effort:** 2h

Auto-configure IM environment variables for Ubuntu GNOME/Wayland sessions using modern `systemd-environment-d` approach.

## Key Insights

1. **Modern Wayland Sessions:** Use `~/.config/environment.d/` instead of `.profile`/`.bashrc`
2. **Required Variables:**
   - `GTK_IM_MODULE=fcitx`
   - `QT_IM_MODULE=fcitx`
   - `XMODIFIERS=@im=fcitx`
   - `SDL_IM_MODULE=fcitx`
3. **im-config Integration:** Still used by Ubuntu, but `environment.d` takes precedence

## Requirements

### Functional
- Auto-create `~/.config/environment.d/90-gonhanh.conf` during installation
- Backup existing IM configuration if present
- Run `im-config -n fcitx5` automatically (with user prompt)
- Detect current session type (X11 vs Wayland)

### Non-functional
- Idempotent - safe to run multiple times
- Preserve user's existing IM settings if not Fcitx5-related
- Clear logging of what was changed

## Architecture

```
install.sh
  ├─> Check if Fcitx5 installed
  ├─> Create environment.d config
  │   └─> Backup if exists
  ├─> Run im-config (interactive)
  └─> Prompt user to log out/in
```

## Related Code Files

### Files to Modify
- `platforms/linux/scripts/install.sh` - Add environment setup

### Files to Create
- `platforms/linux/data/90-gonhanh.conf.template` - Environment vars template

## Implementation Steps

1. **Create environment template**
   ```bash
   # File: platforms/linux/data/90-gonhanh.conf.template
   GTK_IM_MODULE=fcitx
   QT_IM_MODULE=fcitx
   XMODIFIERS=@im=fcitx
   SDL_IM_MODULE=fcitx
   INPUT_METHOD=fcitx
   ```

2. **Update install.sh**
   - Add function `setup_environment_vars()`
   - Check if `~/.config/environment.d/` exists, create if not
   - Copy template to `~/.config/environment.d/90-gonhanh.conf`
   - Backup existing file if present

3. **Add im-config integration**
   - Check if `im-config` available
   - Prompt user before running `im-config -n fcitx5`
   - Log action taken

4. **Session detection**
   - Detect XDG_SESSION_TYPE (X11 vs Wayland)
   - Warn if Wayland detected but KIMPanel not installed
   - Provide instructions for KIMPanel installation

## Todo List

- [ ] Create `90-gonhanh.conf.template`
- [ ] Implement `setup_environment_vars()` in install.sh
- [ ] Add im-config integration
- [ ] Add session type detection
- [ ] Test on Ubuntu 22.04 and 24.04
- [ ] Update docs/install-linux.md with environment info

## Success Criteria

- Environment vars auto-configured during install
- User prompted before making system changes
- Works on both X11 and Wayland sessions
- Idempotent - safe to re-run
- Clear instructions if manual intervention needed

## Risk Assessment

**Risk:** Breaking existing IM setup
**Mitigation:** Backup existing config, only modify if Fcitx5-related

**Risk:** User not logging out after install
**Mitigation:** Clear warning message, offer to add to FAQ

## Security Considerations

- Don't override user settings without permission
- Backup before modifying configuration files
- Use proper file permissions (644 for config files)

## Next Steps

After completion:
- Proceed to Phase 02: GNOME/Wayland Compatibility
- Update installation documentation
