# Research Report: Ubuntu-specific Fcitx5 Integration Patterns (2026)

## Overview
This report details the installation, configuration, and packaging best practices for Fcitx5 on Ubuntu LTS (20.04, 22.04, 24.04), with a focus on GNOME/Wayland compatibility and Vietnamese input method development.

## 1. Ubuntu LTS Support Matrix (2026)

| Version | Status | Installation Strategy |
| :--- | :--- | :--- |
| **24.04 LTS** | Native Support | `sudo apt install fcitx5` (Ver 5.1+) |
| **22.04 LTS** | Native Support | `sudo apt install fcitx5` (Ver 5.0+) |
| **20.04 LTS** | Outdated/Missing | Use PPA `ppa:fcitx-team/stable` or Backports. |

**Recommendation:** For 20.04, it is highly recommended to use the official Fcitx PPA to ensure compatibility with modern addons (Fcitx 5 core is required).

## 2. System Integration & Configuration

### A. Environment Variables
Ubuntu GNOME (Wayland) relies on `systemd-environment-d`.

**Path:** `~/.config/environment.d/90-input.conf`
```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
```

### B. im-config vs Manual
*   **im-config:** Still the standard tool for Ubuntu. Running `im-config -n fcitx5` updates `~/.xinputrc`.
*   **GNOME Settings:** Ensure "IBus" is NOT the primary input source in GNOME Settings -> Keyboard.

## 3. GNOME Desktop Issues & Solutions

### A. Candidate Window Positioning (Wayland)
GNOME doesn't support the Wayland `input-method-v2` protocol natively for popups.
*   **Fix:** Users MUST install the **Gnome Shell Extension: Input Method Panel** (KIMPanel).
*   **Package:** `gnome-shell-extension-kimpanel`.

### B. Electron / Chromium (Chrome, VS Code, Discord)
By default, Electron apps on Wayland don't support IME.
*   **Required Flags:** `--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime`
*   **Note:** In 2026, many apps have this enabled, but issues persist with "double character" bugs in `text-input-v3`. Setting `GTK_IM_MODULE=fcitx` often fixes this by falling back to the Fcitx GTK module.

## 4. .deb Packaging Best Practices for Fcitx5 Addons

### A. Build Requirements
*   **Build System:** CMake (3.13+)
*   **Dependencies:** `extra-cmake-modules`, `fcitx5-modules-dev`, `libfcitx5core-dev`, `libfcitx5utils-dev`.
*   **Vietnamese Core:** If using a custom engine (like TVietKey core), it should be bundled or linked as a static lib.

### B. Debian Control File (Template)
```control
Source: fcitx5-tvietkey
Section: utils
Priority: optional
Build-Depends: debhelper-compat (= 13), cmake, extra-cmake-modules, fcitx5-modules-dev, gettext
Standards-Version: 4.6.0

Package: fcitx5-tvietkey
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}, fcitx5
Description: TVietKey engine for Fcitx5
 Vietnamese input method for Fcitx5 based on TVietKey core.
```

### C. Registration (Metainfo)
Addons register via an `.xml.in` file (e.g., `org.fcitx.Fcitx5.Addon.TVietKey.metainfo.xml.in`).
*   This file defines the icon, name, and engine properties.
*   CMake handles the installation to `/usr/share/metainfo/` and `/usr/share/fcitx5/addon/`.

## 5. User Experience (First-time Setup)
To wow the user and ensure a premium experience:
1.  **Auto-Configuration Script:** Provide a post-install script or a "Fix System Settings" button that:
    -   Detects if `KIMPanel` is missing and prompts to install.
    -   Sets environment variables in `environment.d`.
    -   Runs `im-config -n fcitx5`.
2.  **Diagnostics:** Bundle `fcitx5-diagnose` usage in the README to help troubleshoot.
3.  **Themes:** Include a modern, sleek Fcitx5 theme (e.g., matching Ubuntu's Yaru or a custom TVietKey theme).

## Unresolved Questions
1.  **Specific GTK4 focus bug:** Is there a definitive fix for the "lost focus" issue in GTK4 apps without KIMPanel?
2.  **Ubuntu 20.04 PPA stability:** Is the `fcitx-team` PPA actively maintained for 20.04 in 2026?

## Sources:
- [fcitx-im.org Documentation](https://fcitx-im.org/wiki/Fcitx_5)
- [Arch Wiki: Fcitx5](https://wiki.archlinux.org/title/Fcitx5)
- [Fcitx5-Bamboo GitHub](https://github.com/fcitx/fcitx5-bamboo)
- [Ubuntu Wiki: Input Methods](https://wiki.ubuntu.com/InputMethod)
