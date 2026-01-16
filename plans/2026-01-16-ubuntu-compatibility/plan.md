---
title: "Ubuntu Compatibility & Bug Fixes"
description: "Fix bugs and improve Gõ Nhanh compatibility with Ubuntu GNOME, create .deb packaging"
status: pending
priority: P1
effort: 12h
branch: main
tags: [linux, ubuntu, fcitx5, packaging, bugfix]
created: 2026-01-16
---

# Ubuntu Compatibility & Bug Fixes Plan

## Overview

Improve Gõ Nhanh Linux support for Ubuntu 22.04+ with GNOME desktop. Fix compatibility issues, enhance user experience, create native .deb packages for easier distribution.

## Current Status

- **Platform:** Linux (Fcitx5 backend) - Beta
- **Testing:** Ubuntu 24.04 with Fcitx5 5.1.7
- **Build System:** CMake + Rust core
- **Distribution:** Manual install script only

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Environment Integration | Pending | 2h | [phase-01](./phase-01-environment-integration.md) |
| 2 | GNOME/Wayland Compatibility | Pending | 3h | [phase-02-gnome-wayland-compatibility.md) |
| 3 | Debian Package Creation | Pending | 4h | [phase-03-debian-packaging.md) |
| 4 | User Experience Improvements | Pending | 2h | [phase-04-ux-improvements.md) |
| 5 | Testing & Validation | Done (2026-01-16) | 1h | [phase-05-testing-validation.md) |

## Dependencies

### External
- Ubuntu 22.04+ (native Fcitx5 support)
- Fcitx5 framework (5.0+)
- GNOME Shell Extension: Input Method Panel (KIMPanel)
- CMake 3.16+, debhelper 13+

### Internal
- Rust core engine (`core/` directory)
- Existing Linux platform code (`platforms/linux/`)

## Key Objectives

1. **Environment Auto-Configuration**: Automatic setup of IM environment variables
2. **GNOME Integration**: Fix candidate window positioning on Wayland
3. **Native Packaging**: `.deb` package with proper dependencies
4. **User Onboarding**: Clear setup instructions and diagnostics
5. **Multi-Version Support**: Ubuntu 22.04 LTS and 24.04 LTS

## Success Criteria

- [ ] One-command installation via `.deb` package
- [ ] Automatic environment configuration
- [ ] Candidate window positioned correctly in GNOME
- [ ] Works in all major apps (Chrome, VS Code, Terminal, LibreOffice)
- [ ] Clear troubleshooting documentation
- [ ] CI/CD builds `.deb` packages automatically

## Related Research

- [Ubuntu Fcitx5 Integration Research](../reports/researcher-2026-01-16-1552-ubuntu-fcitx5-integration.md)
