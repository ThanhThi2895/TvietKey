# Manual Testing Checklist

Testing guide for Gõ Nhanh on Ubuntu.

## Prerequisites

- [ ] Fresh Ubuntu 22.04 or 24.04 VM/container
- [ ] GNOME desktop installed
- [ ] Test both X11 and Wayland sessions

## Automated Testing

```bash
# Run integration tests
./platforms/linux/tests/integration-test.sh
```

## Installation Testing

### From .deb Package

- [ ] Download .deb package from releases
- [ ] Run: `sudo dpkg -i fcitx5-gonhanh_*.deb`
- [ ] Verify no dependency errors
- [ ] Check files installed: `dpkg -L fcitx5-gonhanh`

### From Source (Manual Install)

- [ ] Run: `./platforms/linux/scripts/install.sh`
- [ ] Verify success message
- [ ] Check files: `ls ~/.local/lib/fcitx5/`

## Configuration Testing

- [ ] Environment vars created: `cat ~/.config/environment.d/90-gonhanh.conf`
- [ ] Log out and log in
- [ ] Verify vars loaded: `env | grep fcitx`
- [ ] Expected vars:
  - `GTK_IM_MODULE=fcitx`
  - `QT_IM_MODULE=fcitx`
  - `XMODIFIERS=@im=fcitx`

## Fcitx5 Testing

- [ ] Run: `fcitx5-configtool`
- [ ] Add "Gõ Nhanh" to input methods
- [ ] Switch to Gõ Nhanh (Ctrl+Space)
- [ ] Type: `vietj namm` → should become `việt nam`
- [ ] Type: `xin chaof` → should become `xin chào`
- [ ] ESC restores original: `user` → `úẻ` → ESC → `user`

## App Testing

Test Vietnamese input in each app:

- [ ] Terminal (GNOME Terminal / Konsole)
- [ ] Text Editor (gedit / Kate)
- [ ] Browser (Chrome / Firefox)
- [ ] VS Code
- [ ] LibreOffice Writer
- [ ] Telegram / Discord

## CLI Testing

- [ ] Run: `gn status` - shows current state
- [ ] Run: `gn diagnose` - shows system check
- [ ] Run: `gn fix-env` - configures environment
- [ ] Run: `gn help` - shows all commands
- [ ] Run: `gn telex` - switches to Telex
- [ ] Run: `gn vni` - switches to VNI
- [ ] Run: `gn on` / `gn off` - toggles input

## GNOME Wayland Specific

- [ ] Check session: `echo $XDG_SESSION_TYPE` (should be "wayland")
- [ ] Check KIMPanel installed: `gn diagnose`
- [ ] Candidate window positioned near cursor
- [ ] No focus loss when typing
- [ ] If KIMPanel missing: `gn fix-gnome`

## GNOME X11 Specific

- [ ] Check session: `echo $XDG_SESSION_TYPE` (should be "x11")
- [ ] Candidate window works without KIMPanel
- [ ] No special configuration needed

## Uninstallation Testing

### .deb Package

- [ ] Run: `sudo apt remove fcitx5-gonhanh`
- [ ] Verify addon removed: `ls /usr/lib/*/fcitx5/`
- [ ] Environment vars should remain (user data)

### Manual Install

- [ ] Run: `./platforms/linux/scripts/install.sh -u`
- [ ] Verify files removed: `ls ~/.local/lib/fcitx5/`

## Performance Testing

- [ ] Type 50 characters, check latency feels instant (<1ms)
- [ ] Check RAM usage: `ps aux | grep -i gonhanh`
- [ ] Should be <10MB total
- [ ] No noticeable CPU usage during idle

## Edge Cases

- [ ] Switching apps preserves input state
- [ ] System language change doesn't break IM
- [ ] Sleep/wake preserves configuration
- [ ] Multi-monitor support

## Test Matrix Results

| Ubuntu | Desktop | Session | Install | Input | CLI | Overall |
|--------|---------|---------|---------|-------|-----|---------|
| 22.04 | GNOME | Wayland | | | | |
| 22.04 | GNOME | X11 | | | | |
| 24.04 | GNOME | Wayland | | | | |
| 24.04 | GNOME | X11 | | | | |

Mark each cell: PASS / FAIL / SKIP

## Troubleshooting Common Issues

### Can't type Vietnamese

```bash
gn diagnose     # Check what's wrong
gn fix-env      # Fix environment vars
# Log out and log in
```

### Candidate window not showing (GNOME Wayland)

```bash
gn fix-gnome    # Install KIMPanel
gnome-extensions enable kimpanel@kde.org
```

### Works in Terminal but not Chrome/VS Code

Create `~/.config/electron-flags.conf`:
```
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--enable-wayland-ime
```

### Fcitx5 not starting

```bash
fcitx5 -d       # Start daemon
fcitx5 --version  # Check installed
```

## Sign-off

- Tester: _______________
- Date: _______________
- Ubuntu Version: _______________
- Result: PASS / FAIL
- Notes: _______________
