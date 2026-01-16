#!/bin/bash
# Build Debian package for fcitx5-gonhanh
# Usage: ./build-deb.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Check dependencies
check_dependencies() {
    info "Checking build dependencies..."

    local missing=()

    # Essential build tools
    command -v dpkg-buildpackage &> /dev/null || missing+=("dpkg-dev")
    command -v debuild &> /dev/null || missing+=("devscripts")
    command -v dh &> /dev/null || missing+=("debhelper")

    # Build dependencies
    command -v cmake &> /dev/null || missing+=("cmake")
    command -v cargo &> /dev/null || missing+=("cargo")
    command -v rustc &> /dev/null || missing+=("rustc")
    command -v pkg-config &> /dev/null || missing+=("pkg-config")

    # Fcitx5 development files (use Fcitx5Core with capital F)
    if ! pkg-config --exists Fcitx5Core 2>/dev/null; then
        missing+=("libfcitx5core-dev" "libfcitx5config-dev" "libfcitx5utils-dev" "fcitx5-modules-dev")
    fi

    # xkbcommon for keycode mapping
    if ! pkg-config --exists xkbcommon 2>/dev/null; then
        missing+=("libxkbcommon-dev")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  • $dep"
        done
        echo ""
        info "Install with:"
        echo "  sudo apt install ${missing[*]}"
        exit 1
    fi

    success "All build dependencies installed"
}

# Clean previous builds
clean_build() {
    info "Cleaning previous builds..."
    cd "$PROJECT_ROOT"

    # Clean Debian build artifacts
    rm -rf debian/.debhelper debian/fcitx5-gonhanh debian/tmp debian/files
    rm -f debian/*.log debian/*.substvars

    # Clean Rust artifacts
    cd core && cargo clean 2>/dev/null || true
    cd "$PROJECT_ROOT"

    success "Build directory cleaned"
}

# Build source package
build_source() {
    info "Building source package..."
    cd "$PROJECT_ROOT"

    dpkg-buildpackage -S -us -uc

    success "Source package built"
}

# Build binary package
build_binary() {
    info "Building binary package..."
    cd "$PROJECT_ROOT"

    dpkg-buildpackage -b -us -uc

    success "Binary package built"
}

# Lint package
lint_package() {
    info "Linting package..."
    cd "$PROJECT_ROOT/.."

    if command -v lintian &> /dev/null; then
        lintian --pedantic fcitx5-gonhanh_*.deb || true
    else
        warning "lintian not installed, skipping lint check"
    fi
}

# Show build results
show_results() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "Package built successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    info "Build artifacts in: $(dirname "$PROJECT_ROOT")"
    echo ""
    ls -lh "$PROJECT_ROOT"/../fcitx5-gonhanh_* 2>/dev/null || true
    echo ""
    info "Install with:"
    echo "  sudo dpkg -i $(dirname "$PROJECT_ROOT")/fcitx5-gonhanh_*.deb"
    echo "  sudo apt install -f  # Fix dependencies if needed"
    echo ""
}

# Main execution
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Building fcitx5-gonhanh Debian Package"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    check_dependencies
    clean_build
    build_binary
    lint_package
    show_results
}

# Run main
main "$@"
