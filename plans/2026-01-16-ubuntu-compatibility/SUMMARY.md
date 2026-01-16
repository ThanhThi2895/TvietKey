# Implementation Plan Summary: Ubuntu Compatibility & Bug Fixes

**Plan Directory:** `plans/2026-01-16-ubuntu-compatibility/`
**Created:** 2026-01-16
**Status:** Ready for Implementation
**Estimated Effort:** 12 hours

## Executive Summary

Comprehensive plan to make Gõ Nhanh production-ready on Ubuntu 22.04+ with GNOME desktop. Focuses on fixing compatibility issues, improving user experience, and creating native .deb packages for distribution.

## Problem Statement

Current state:
- Linux support marked as "Beta"
- Manual installation via shell script
- No Ubuntu-specific optimizations
- GNOME/Wayland compatibility issues (candidate window positioning)
- Missing environment auto-configuration
- No native package distribution

## Solution Overview

5-phase implementation plan covering:
1. **Environment Integration** - Auto-configure IM environment variables using systemd-environment-d
2. **GNOME/Wayland Compatibility** - Fix candidate window via KIMPanel extension
3. **Debian Packaging** - Create .deb package following Debian standards
4. **UX Improvements** - Enhanced CLI diagnostics and troubleshooting guides
5. **Testing & Validation** - Comprehensive testing on Ubuntu 22.04/24.04

## Key Deliverables

### Technical
- Native `.deb` package: `fcitx5-gonhanh`
- Auto-configuration scripts for environment setup
- Enhanced CLI tool with diagnostics (`gn diagnose`, `gn fix-*`)
- CI/CD pipeline for automated .deb builds

### Documentation
- Ubuntu-specific installation guide
- Troubleshooting documentation
- Manual testing checklist
- Integration test suite

## Implementation Phases

### Phase 01: Environment Integration (2h)
**Objective:** Auto-configure IM environment variables

**Key Changes:**
- Create `~/.config/environment.d/90-gonhanh.conf` during install
- Integrate with `im-config`
- Detect session type (X11 vs Wayland)
- Backup existing configs

**Files:**
- Modify: `platforms/linux/scripts/install.sh`
- Create: `platforms/linux/data/90-gonhanh.conf.template`

### Phase 02: GNOME/Wayland Compatibility (3h)
**Objective:** Fix candidate window positioning on GNOME

**Key Changes:**
- Detect GNOME + Wayland environment
- Auto-install KIMPanel extension
- Provide manual instructions if auto-install fails
- Add Electron app workarounds

**Files:**
- Modify: `platforms/linux/scripts/install.sh`

**Critical Dependency:** `gnome-shell-extension-kimpanel` package

### Phase 03: Debian Packaging (4h)
**Objective:** Create production-ready .deb package

**Key Changes:**
- Complete `debian/` directory structure
- Package metadata and dependencies
- Post-install scripts for setup
- Build automation with debhelper + CMake

**Files Created:**
- `debian/control` - Package metadata
- `debian/rules` - Build rules
- `debian/changelog` - Version history
- `debian/postinst` - Post-install setup
- `debian/prerm` - Pre-removal cleanup
- `debian/copyright` - License info

**CI Integration:**
- GitHub Actions workflow for .deb builds
- Multi-version testing (Ubuntu 22.04, 24.04)

### Phase 04: UX Improvements (2h)
**Objective:** Enhance first-time setup experience

**Key Changes:**
- Enhanced `gn` CLI tool with diagnostics
- `gn diagnose` - System health check
- `gn fix-env` - Auto-fix environment
- `gn fix-gnome` - Install KIMPanel
- Colored terminal output
- Comprehensive troubleshooting guide

**Files:**
- Modify: `platforms/linux/scripts/gonhanh-cli.sh`
- Create: `docs/troubleshooting-ubuntu.md`

### Phase 05: Testing & Validation (1h)
**Objective:** Validate all changes before release

**Testing Matrix:**
- Ubuntu 22.04 LTS (GNOME X11 + Wayland)
- Ubuntu 24.04 LTS (GNOME X11 + Wayland)

**Test Coverage:**
- Installation from .deb
- Vietnamese input in various apps
- CLI diagnostics accuracy
- Package quality (lintian checks)
- Performance (latency, memory)

**Files:**
- Create: `platforms/linux/tests/integration-test.sh`
- Create: `.github/workflows/build-deb.yml`
- Create: `platforms/linux/TESTING.md`

## Technical Architecture

### Package Structure
```
fcitx5-gonhanh_1.0.0-1_amd64.deb
├── /usr/lib/fcitx5/gonhanh.so          # Fcitx5 addon
├── /usr/lib/libgonhanh_core.so         # Rust core engine
├── /usr/share/fcitx5/addon/gonhanh.conf
├── /usr/share/fcitx5/inputmethod/gonhanh.conf
└── /usr/bin/gn                         # CLI tool
```

### Environment Configuration
```
~/.config/environment.d/90-gonhanh.conf:
  GTK_IM_MODULE=fcitx
  QT_IM_MODULE=fcitx
  XMODIFIERS=@im=fcitx
  SDL_IM_MODULE=fcitx
```

### GNOME Integration
```
GNOME Wayland → Requires KIMPanel extension
GNOME X11 → Works natively
```

## Dependencies

### Build Dependencies
- `debhelper-compat (>= 13)`
- `cmake (>= 3.16)`
- `fcitx5-modules-dev`
- `libfcitx5core-dev`, `libfcitx5config-dev`, `libfcitx5utils-dev`
- `cargo`, `rustc (>= 1.70)`

### Runtime Dependencies
- `fcitx5`
- `gnome-shell-extension-kimpanel` (recommended for GNOME Wayland)

## Security Considerations

- Package signing with GPG for PPA
- No world-writable files
- Maintainer scripts validated for security
- Environment variables only modified with user permission
- Sudo only requested when necessary

## Performance Targets

Maintain existing performance:
- **Latency:** <1ms per keystroke
- **Memory:** <10MB RAM footprint
- **Package Size:** <5MB compressed

## Unresolved Questions

1. **Ubuntu 20.04 Support?**
   - Requires PPA for Fcitx5 (not in default repos)
   - Decision: Document 20.04 support as "experimental" with PPA instructions

2. **GTK4 Focus Issues?**
   - Research ongoing for definitive fix without KIMPanel
   - Mitigation: KIMPanel works for most apps

3. **PPA Hosting?**
   - Options: Launchpad PPA vs GitHub Releases only
   - Decision needed: Create official PPA or rely on .deb downloads

## Success Metrics

**Before:**
- Manual installation required
- Beta status
- GNOME Wayland issues
- No diagnostics
- Installation success rate: ~70%

**After (Target):**
- One-command install: `sudo apt install fcitx5-gonhanh`
- Production-ready status
- GNOME Wayland fully supported
- Self-diagnostic tools
- Installation success rate: >95%

## Next Steps After Plan Completion

1. **Implementation:** Execute phases 01-05 sequentially
2. **Beta Testing:** 10-20 Ubuntu users test .deb package
3. **Documentation:** Update README, website with PPA instructions
4. **PPA Setup:** Create Launchpad PPA for easier distribution
5. **Release:** Tag v1.0.0-ubuntu, announce on social media
6. **Monitoring:** Collect user feedback, iterate on UX issues

## Related Documents

- [Phase 01: Environment Integration](./phase-01-environment-integration.md)
- [Phase 02: GNOME/Wayland Compatibility](./phase-02-gnome-wayland-compatibility.md)
- [Phase 03: Debian Packaging](./phase-03-debian-packaging.md)
- [Phase 04: UX Improvements](./phase-04-ux-improvements.md)
- [Phase 05: Testing & Validation](./phase-05-testing-validation.md)
- [Research: Ubuntu Fcitx5 Integration](../reports/researcher-2026-01-16-1552-ubuntu-fcitx5-integration.md)

---

**Plan Ready:** This plan is comprehensive and ready for implementation. All phases are well-defined with clear objectives, steps, and success criteria.
