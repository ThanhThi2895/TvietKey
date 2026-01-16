#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Uninstall
[[ "$1" == "-u" || "$1" == "--uninstall" ]] && {
    rm -f ~/.local/lib/fcitx5/gonhanh.so ~/.local/lib/libgonhanh_core.so
    rm -f ~/.local/share/fcitx5/addon/gonhanh.conf ~/.local/share/fcitx5/inputmethod/gonhanh.conf
    rm -f ~/.local/bin/gn
    rm -rf ~/.config/gonhanh
    # Note: We don't remove environment.d config as user may want to keep it
    success "Uninstalled. Run: fcitx5 -r"
    exit 0
}

# Detect source: tarball (lib/) or build (../build/)
[[ -f "$DIR/lib/gonhanh.so" ]] && SRC="$DIR" || SRC="$(dirname "$DIR")"
[[ -f "$SRC/lib/gonhanh.so" ]] && LIB="$SRC/lib" || LIB="$SRC/build"
[[ -f "$SRC/share/fcitx5/addon/gonhanh.conf" ]] && DATA="$SRC/share/fcitx5" || DATA="$SRC/data"

# Find Rust lib
RUST=""
for p in "$LIB/libgonhanh_core.so" "$SRC/../../core/target/release/libgonhanh_core.so" "$SRC/../../core/target/debug/libgonhanh_core.so"; do
    [[ -f "$p" ]] && RUST="$p" && break
done

[[ ! -f "$LIB/gonhanh.so" || -z "$RUST" ]] && error "Build not found" && exit 1

# Check if Fcitx5 is installed
check_fcitx5() {
    if ! command -v fcitx5 &> /dev/null; then
        error "Fcitx5 not installed"
        info "Install with: sudo apt install fcitx5 fcitx5-configtool"
        exit 1
    fi
    success "Fcitx5 found: $(fcitx5 --version | head -1)"
}

# Detect desktop environment and session type
detect_session() {
    local desktop="${XDG_CURRENT_DESKTOP:-Unknown}"
    local session="${XDG_SESSION_TYPE:-Unknown}"
    info "Desktop: $desktop, Session: $session"

    # Return values for use in other functions
    echo "$desktop:$session"
}

# Setup environment variables for IM
setup_environment_vars() {
    local env_dir="$HOME/.config/environment.d"
    local env_file="$env_dir/90-gonhanh.conf"
    local template=""

    # Find template file
    for p in "$DATA/90-gonhanh.conf.template" "$SRC/data/90-gonhanh.conf.template"; do
        [[ -f "$p" ]] && template="$p" && break
    done

    if [[ -z "$template" ]]; then
        warning "Environment template not found, skipping environment setup"
        return 0
    fi

    info "Configuring environment variables..."

    # Create directory if doesn't exist
    mkdir -p "$env_dir"

    # Backup existing file if present
    if [[ -f "$env_file" ]]; then
        local backup="$env_file.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$env_file" "$backup"
        info "Backed up existing config to: $backup"
    fi

    # Copy template
    cp "$template" "$env_file"
    chmod 644 "$env_file"

    success "Environment variables configured at: $env_file"
}

# Configure im-config (Ubuntu's input method selector)
setup_im_config() {
    if ! command -v im-config &> /dev/null; then
        info "im-config not available, skipping"
        return 0
    fi

    info "Configuring input method framework..."

    # Check current IM setting
    local current_im=""
    if [[ -f "$HOME/.xinputrc" ]]; then
        current_im=$(grep "run_im" "$HOME/.xinputrc" 2>/dev/null | cut -d' ' -f2 || echo "")
    fi

    if [[ "$current_im" == "fcitx5" ]]; then
        success "im-config already set to fcitx5"
        return 0
    fi

    # Ask user if they want to configure
    echo ""
    echo "Current input method: ${current_im:-none}"
    read -p "Set fcitx5 as default input method? [Y/n] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        im-config -n fcitx5
        success "Input method set to fcitx5"
    else
        info "Skipped im-config setup"
    fi
}

# Check for KIMPanel on GNOME Wayland
check_gnome_wayland() {
    local session_info="$1"
    local desktop=$(echo "$session_info" | cut -d: -f1)
    local session=$(echo "$session_info" | cut -d: -f2)

    # Only check if GNOME + Wayland
    if [[ "$desktop" != *"GNOME"* ]] || [[ "$session" != "wayland" ]]; then
        return 0
    fi

    info "GNOME Wayland detected - checking KIMPanel..."

    # Check if KIMPanel installed
    if [[ -d "$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org" ]] || \
       [[ -d "/usr/share/gnome-shell/extensions/kimpanel@kde.org" ]] || \
       dpkg -l 2>/dev/null | grep -q gnome-shell-extension-kimpanel; then
        success "KIMPanel extension found"
        return 0
    fi

    # KIMPanel not found - warn user
    echo ""
    warning "KIMPanel extension not installed"
    info "KIMPanel is required for proper candidate window positioning on GNOME Wayland"
    info "Without it, you may not see the candidate window when typing"
    echo ""
    read -p "Install gnome-shell-extension-kimpanel now? [Y/n] " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        if sudo apt update && sudo apt install -y gnome-shell-extension-kimpanel; then
            success "KIMPanel installed"
            info "Please enable it in Extensions app (gnome-extensions-app)"
            info "Or run: gnome-extensions enable kimpanel@kde.org"
        else
            error "Failed to install KIMPanel"
            info "You can install it manually: sudo apt install gnome-shell-extension-kimpanel"
        fi
    else
        info "Skipped KIMPanel installation"
        info "Install later with: sudo apt install gnome-shell-extension-kimpanel"
    fi
}

# Install
echo ""
info "Installing Gõ Nhanh..."
echo ""

# Pre-install checks
check_fcitx5
session_info=$(detect_session)

# Install files
mkdir -p ~/.local/lib/fcitx5 ~/.local/share/fcitx5/{addon,inputmethod}
cp "$LIB/gonhanh.so" ~/.local/lib/fcitx5/
cp "$RUST" ~/.local/lib/
[[ -f "$DATA/addon/gonhanh.conf" ]] && cp "$DATA/addon/gonhanh.conf" ~/.local/share/fcitx5/addon/
[[ -f "$DATA/inputmethod/gonhanh.conf" ]] && cp "$DATA/inputmethod/gonhanh.conf" ~/.local/share/fcitx5/inputmethod/
[[ -f "$DATA/gonhanh-addon.conf" ]] && cp "$DATA/gonhanh-addon.conf" ~/.local/share/fcitx5/addon/gonhanh.conf
[[ -f "$DATA/gonhanh.conf" && ! -f "$DATA/addon/gonhanh.conf" ]] && cp "$DATA/gonhanh.conf" ~/.local/share/fcitx5/inputmethod/

success "Addon files installed"

# Install CLI
mkdir -p ~/.local/bin
CLI=""
for p in "$DIR/gonhanh-cli.sh" "$SRC/scripts/gonhanh-cli.sh"; do
    [[ -f "$p" ]] && CLI="$p" && break
done
[[ -n "$CLI" ]] && cp "$CLI" ~/.local/bin/gn && chmod +x ~/.local/bin/gn && success "CLI tool installed: gn"

# Post-install configuration
echo ""
setup_environment_vars
echo ""
setup_im_config
echo ""
check_gnome_wayland "$session_info"

# Final instructions
echo ""
success "✓ Gõ Nhanh installed successfully!"
echo ""
info "Next steps:"
echo "  1. Log out and log in again for environment variables to take effect"
echo "  2. Run: fcitx5-configtool"
echo "  3. Add 'Gõ Nhanh' to your input methods"
echo "  4. Use Ctrl+Space (or your configured hotkey) to switch input methods"
echo ""
info "Troubleshooting:"
echo "  • Run: gn diagnose"
echo "  • Check docs: https://github.com/khaphanspace/gonhanh.org/blob/main/docs/install-linux.md"
echo ""
