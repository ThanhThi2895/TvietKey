#!/bin/bash
# Integration tests for Gõ Nhanh on Ubuntu
# Usage: ./integration-test.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test helpers
test_start() {
    ((TESTS_RUN++))
    echo -n "Testing: $1 ... "
}

test_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}FAIL${NC}: $1"
}

test_skip() {
    echo -e "${YELLOW}SKIP${NC}: $1"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PACKAGE INSTALLATION TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_package_installed() {
    test_start "Package installed"
    if dpkg -l 2>/dev/null | grep -q fcitx5-gonhanh; then
        test_pass
        return 0
    fi
    # Also check for local install
    if [ -f "$HOME/.local/lib/fcitx5/gonhanh.so" ]; then
        test_pass
        return 0
    fi
    test_fail "Package not installed (dpkg or local)"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FILE INSTALLATION TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_addon_library() {
    test_start "Addon library exists"
    # Check common locations for addon library (handles arch-specific paths)
    if ls /usr/lib/*/fcitx5/gonhanh.so &>/dev/null || \
       [ -f "/usr/lib/fcitx5/gonhanh.so" ] || \
       [ -f "$HOME/.local/lib/fcitx5/gonhanh.so" ]; then
        test_pass
        return 0
    fi
    test_fail "Addon library not found"
    return 1
}

test_core_library() {
    test_start "Rust core library exists"
    # Check common locations for core library (handles arch-specific paths)
    if [ -f "/usr/lib/libgonhanh_core.so" ] || \
       ls /usr/lib/*/libgonhanh_core.so &>/dev/null || \
       [ -f "$HOME/.local/lib/libgonhanh_core.so" ]; then
        test_pass
        return 0
    fi
    test_fail "Core library not found"
    return 1
}

test_addon_config() {
    test_start "Addon config exists"
    if [ -f "/usr/share/fcitx5/addon/gonhanh.conf" ] || \
       [ -f "$HOME/.local/share/fcitx5/addon/gonhanh.conf" ]; then
        test_pass
        return 0
    fi
    test_fail "Addon config not found"
    return 1
}

test_inputmethod_config() {
    test_start "Input method config exists"
    if [ -f "/usr/share/fcitx5/inputmethod/gonhanh.conf" ] || \
       [ -f "$HOME/.local/share/fcitx5/inputmethod/gonhanh.conf" ]; then
        test_pass
        return 0
    fi
    test_fail "Input method config not found"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ENVIRONMENT TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_environment_config() {
    test_start "Environment config file exists"
    if [ -f "$HOME/.config/environment.d/90-gonhanh.conf" ]; then
        test_pass
        return 0
    fi
    test_fail "Environment config missing (run: gn fix-env)"
    return 1
}

test_environment_vars() {
    test_start "Environment variables set"
    local missing=0

    if [ "${GTK_IM_MODULE:-}" != "fcitx" ]; then
        ((missing++))
    fi
    if [ "${QT_IM_MODULE:-}" != "fcitx" ]; then
        ((missing++))
    fi
    if [ "${XMODIFIERS:-}" != "@im=fcitx" ]; then
        ((missing++))
    fi

    if [ $missing -eq 0 ]; then
        test_pass
        return 0
    fi
    test_fail "$missing vars not set (re-login or run: gn fix-env)"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLI TOOL TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_cli_installed() {
    test_start "CLI tool (gn) installed"
    if command -v gn &> /dev/null; then
        test_pass
        return 0
    fi
    if [ -f "$HOME/.local/bin/gn" ]; then
        test_pass
        return 0
    fi
    test_fail "gn command not found"
    return 1
}

test_cli_status() {
    test_start "gn status command"
    if gn status &> /dev/null 2>&1; then
        test_pass
        return 0
    fi
    test_fail "gn status failed"
    return 1
}

test_cli_diagnose() {
    test_start "gn diagnose command"
    if gn diagnose &> /dev/null 2>&1; then
        test_pass
        return 0
    fi
    test_fail "gn diagnose failed"
    return 1
}

test_cli_help() {
    test_start "gn help command"
    if gn help &> /dev/null 2>&1; then
        test_pass
        return 0
    fi
    test_fail "gn help failed"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FCITX5 INTEGRATION TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_fcitx5_installed() {
    test_start "Fcitx5 installed"
    if command -v fcitx5 &> /dev/null; then
        test_pass
        return 0
    fi
    test_fail "Fcitx5 not installed"
    return 1
}

test_fcitx5_running() {
    test_start "Fcitx5 running"
    if pgrep -x fcitx5 > /dev/null; then
        test_pass
        return 0
    fi
    test_skip "Fcitx5 not running (start with: fcitx5 -d)"
    return 0
}

test_fcitx5_responsive() {
    test_start "Fcitx5 responsive"
    if ! pgrep -x fcitx5 > /dev/null; then
        test_skip "Fcitx5 not running"
        return 0
    fi
    if fcitx5-remote &> /dev/null; then
        test_pass
        return 0
    fi
    test_fail "Fcitx5 not responding"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GNOME WAYLAND TESTS (conditional)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_gnome_wayland_kimpanel() {
    if [[ "${XDG_CURRENT_DESKTOP:-}" != *"GNOME"* ]] || [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
        return 0
    fi

    test_start "KIMPanel extension (GNOME Wayland)"
    if [ -d "$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
       [ -d "/usr/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
       dpkg -l 2>/dev/null | grep -q gnome-shell-extension-kimpanel; then
        test_pass
        return 0
    fi
    test_fail "KIMPanel missing (run: gn fix-gnome)"
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LIBRARY LOADING TESTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_library_loadable() {
    test_start "Core library loadable"

    local lib_path=""
    # Check common library paths
    if [ -f "/usr/lib/libgonhanh_core.so" ]; then
        lib_path="/usr/lib/libgonhanh_core.so"
    elif [ -f "$HOME/.local/lib/libgonhanh_core.so" ]; then
        lib_path="$HOME/.local/lib/libgonhanh_core.so"
    else
        # Check arch-specific paths
        lib_path=$(ls /usr/lib/*/libgonhanh_core.so 2>/dev/null | head -1)
    fi

    if [ -z "$lib_path" ]; then
        test_fail "Library not found"
        return 1
    fi

    if ldd "$lib_path" 2>&1 | grep -q "not found"; then
        test_fail "Missing dependencies"
        return 1
    fi

    test_pass
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN TEST RUNNER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Gõ Nhanh Integration Tests${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${BLUE}System Info:${NC}"
    echo "  Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
    echo "  Session: ${XDG_SESSION_TYPE:-Unknown}"
    echo "  Ubuntu: $(lsb_release -rs 2>/dev/null || echo 'N/A')"
    echo ""

    # Run all tests
    echo -e "${BLUE}[Package & Files]${NC}"
    test_package_installed || true
    test_addon_library || true
    test_core_library || true
    test_addon_config || true
    test_inputmethod_config || true
    echo ""

    echo -e "${BLUE}[Environment]${NC}"
    test_environment_config || true
    test_environment_vars || true
    echo ""

    echo -e "${BLUE}[CLI Tool]${NC}"
    test_cli_installed || true
    test_cli_status || true
    test_cli_diagnose || true
    test_cli_help || true
    echo ""

    echo -e "${BLUE}[Fcitx5 Integration]${NC}"
    test_fcitx5_installed || true
    test_fcitx5_running || true
    test_fcitx5_responsive || true
    echo ""

    echo -e "${BLUE}[Desktop Specific]${NC}"
    test_gnome_wayland_kimpanel || true
    test_library_loadable || true
    echo ""

    # Summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Test Results${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  Total:  $TESTS_RUN"
    echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${YELLOW}Some tests failed. Run 'gn diagnose' for recommendations.${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
