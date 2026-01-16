# Phase 03: Debian Package Creation

## Context Links
- Research: [Ubuntu Fcitx5 Integration - Section 4](../reports/researcher-2026-01-16-1552-ubuntu-fcitx5-integration.md)
- Reference: `fcitx5-bamboo`, `fcitx5-unikey` packaging
- Code: `platforms/linux/CMakeLists.txt`

## Overview
**Priority:** P1
**Status:** Pending
**Effort:** 4h

Create native `.deb` package for easy Ubuntu installation via `apt install`. Follow Debian packaging standards for Fcitx5 addons.

## Key Insights

1. **Package Name:** `fcitx5-gonhanh` (follows Fcitx5 naming convention)
2. **Build System:** Use `debhelper` with CMake integration
3. **Dependencies:** Auto-detect via `${shlibs:Depends}`
4. **Installation:** Standard Fcitx5 addon paths
5. **Versioning:** Sync with project version (currently 1.0.0)

## Requirements

### Functional
- Single `.deb` file for all components (addon + Rust core)
- Proper dependency resolution
- Maintainer scripts for post-install setup
- Uninstall removes all files cleanly
- Compatible with Ubuntu 22.04+ repositories

### Non-functional
- Follows Debian Policy Manual 4.6.0
- Signed packages (for PPA distribution)
- Build reproducibility
- Lintian-clean (no critical errors)

## Architecture

```
debian/
├── control           # Package metadata + deps
├── rules             # Build instructions (dh + cmake)
├── changelog         # Version history
├── copyright         # License info
├── compat            # debhelper version (13)
├── install           # File installation manifest
├── postinst          # Post-install script
├── prerm             # Pre-removal script
└── source/
    └── format        # "3.0 (native)"
```

## Related Code Files

### Files to Create
- `debian/control` - Package metadata
- `debian/rules` - Build rules
- `debian/changelog` - Version changelog
- `debian/copyright` - BSD-3-Clause license
- `debian/compat` - debhelper compat level
- `debian/install` - File installation manifest
- `debian/postinst` - Post-install maintenance script
- `debian/prerm` - Pre-removal script
- `debian/source/format` - Source format

### Files to Modify
- `platforms/linux/CMakeLists.txt` - Add CPack support (optional)
- `.github/workflows/ci.yml` - Add .deb build job

## Implementation Steps

### 1. Create `debian/control`

```control
Source: fcitx5-gonhanh
Section: utils
Priority: optional
Maintainer: Kha Phan <nhatkha1407@gmail.com>
Build-Depends: debhelper-compat (= 13),
               cmake (>= 3.16),
               pkg-config,
               fcitx5-modules-dev,
               libfcitx5core-dev,
               libfcitx5config-dev,
               libfcitx5utils-dev,
               libxkbcommon-dev,
               cargo,
               rustc (>= 1.70)
Standards-Version: 4.6.0
Homepage: https://github.com/khaphanspace/gonhanh.org
Vcs-Git: https://github.com/khaphanspace/gonhanh.org.git
Vcs-Browser: https://github.com/khaphanspace/gonhanh.org

Package: fcitx5-gonhanh
Architecture: any
Depends: ${shlibs:Depends},
         ${misc:Depends},
         fcitx5
Recommends: gnome-shell-extension-kimpanel
Description: Vietnamese input method for Fcitx5
 Gõ Nhanh is a high-performance Vietnamese input method engine with:
  - Telex and VNI input methods
  - Auto-restore English words
  - Smart mode switching per application
  - <1ms latency, ~5MB RAM footprint
  - Phonetics-based algorithm (no lookup tables)
 .
 This package provides the Fcitx5 addon and Rust core engine.
```

### 2. Create `debian/rules`

```makefile
#!/usr/bin/make -f

export DEB_BUILD_MAINT_OPTIONS = hardening=+all

%:
	dh $@ --buildsystem=cmake

override_dh_auto_configure:
	# Build Rust core first
	cd core && cargo build --release
	# Configure CMake
	dh_auto_configure -- \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_TESTS=OFF

override_dh_auto_clean:
	cd core && cargo clean || true
	dh_auto_clean
```

### 3. Create `debian/changelog`

```
fcitx5-gonhanh (1.0.0-1) unstable; urgency=medium

  * Initial release for Ubuntu
  * Fcitx5 addon for Vietnamese input
  * Telex and VNI support
  * Auto-restore English words feature

 -- Kha Phan <nhatkha1407@gmail.com>  Thu, 16 Jan 2026 15:00:00 +0700
```

### 4. Create `debian/postinst`

```bash
#!/bin/bash
set -e

case "$1" in
    configure)
        # Setup environment variables
        ENV_DIR="$HOME/.config/environment.d"
        ENV_FILE="$ENV_DIR/90-gonhanh.conf"

        if [ ! -d "$ENV_DIR" ]; then
            mkdir -p "$ENV_DIR"
        fi

        if [ ! -f "$ENV_FILE" ]; then
            cat > "$ENV_FILE" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF
        fi

        # Restart Fcitx5 if running
        if pgrep fcitx5 > /dev/null; then
            fcitx5 -r || true
        fi

        echo "✓ Gõ Nhanh installed successfully!"
        echo "  Please log out and log in again for environment variables to take effect."
        echo "  Then run: fcitx5-configtool to add Gõ Nhanh to input methods."
        ;;
esac

#DEBHELPER#
exit 0
```

### 5. Create `debian/prerm`

```bash
#!/bin/bash
set -e

case "$1" in
    remove|upgrade)
        # Stop Fcitx5 before removal
        if pgrep fcitx5 > /dev/null; then
            fcitx5-remote -e || true
        fi
        ;;
esac

#DEBHELPER#
exit 0
```

### 6. Create `debian/install`

```
# Addon and core libraries installed by CMake via dh_auto_install
# This file can be empty if CMake handles all installation
```

### 7. Create `debian/copyright`

```
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: gonhanh
Upstream-Contact: Kha Phan <nhatkha1407@gmail.com>
Source: https://github.com/khaphanspace/gonhanh.org

Files: *
Copyright: 2025 Gõ Nhanh Contributors
License: BSD-3-Clause

License: BSD-3-Clause
 [Full BSD-3-Clause text from LICENSE file]
```

### 8. Build Script

Create `scripts/build-deb.sh`:
```bash
#!/bin/bash
set -e

VERSION=$(grep '^version' Cargo.toml | head -1 | cut -d'"' -f2)
PACKAGE="fcitx5-gonhanh"

echo "Building ${PACKAGE}_${VERSION}"

# Create debian changelog if doesn't exist
if [ ! -f debian/changelog ]; then
    dch --create --package "$PACKAGE" --newversion "$VERSION-1" \
        "Initial release"
fi

# Build package
dpkg-buildpackage -us -uc -b

echo "✓ Package built: ../${PACKAGE}_${VERSION}-1_$(dpkg --print-architecture).deb"
```

## Todo List

- [ ] Create `debian/` directory structure
- [ ] Write debian/control with correct dependencies
- [ ] Write debian/rules for build automation
- [ ] Create debian/changelog
- [ ] Write debian/postinst for environment setup
- [ ] Write debian/prerm for cleanup
- [ ] Create debian/copyright
- [ ] Test build on Ubuntu 22.04
- [ ] Test build on Ubuntu 24.04
- [ ] Run lintian checks
- [ ] Test installation from .deb
- [ ] Test upgrade scenario
- [ ] Test uninstallation
- [ ] Add CI/CD job for automated builds

## Success Criteria

- [ ] .deb package builds cleanly
- [ ] Passes lintian checks (no errors)
- [ ] Installs all files to correct locations
- [ ] Post-install sets up environment vars
- [ ] Uninstall removes all files
- [ ] Works on Ubuntu 22.04 and 24.04
- [ ] Can be uploaded to PPA

## Risk Assessment

**Risk:** Build dependencies missing on older Ubuntu
**Mitigation:** Document required PPAs, test on LTS versions

**Risk:** Rust toolchain version mismatch
**Mitigation:** Specify minimum Rust version in control file

**Risk:** Post-install script fails for some users
**Mitigation:** Make all post-install actions optional, log errors

## Security Considerations

- Sign packages with GPG key for PPA distribution
- Verify checksums during build
- Don't run arbitrary code in maintainer scripts
- Proper file permissions (no world-writable files)

## Next Steps

After completion:
- Create PPA repository for distribution
- Add installation instructions: `sudo apt install fcitx5-gonhanh`
- Update README with PPA instructions
- Proceed to Phase 04: UX Improvements
