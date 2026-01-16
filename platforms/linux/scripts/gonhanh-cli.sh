#!/bin/bash
# Gõ Nhanh CLI
# Usage: gn [command]

VERSION=$(cat ~/.local/share/gonhanh/version 2>/dev/null || echo "1.0.0")
CONFIG_DIR="$HOME/.config/gonhanh"
METHOD_FILE="$CONFIG_DIR/method"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Legacy color codes for compatibility
G="$GREEN" Y="$YELLOW" B="$BLUE" N="$NC"

# Helper functions
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Show status: ● BẬT │ telex or ○ TẮT │ telex
show_status() {
    METHOD=$(cat "$METHOD_FILE" 2>/dev/null || echo "telex")
    STATE=$(fcitx5-remote 2>/dev/null)
    if [[ "$STATE" == "2" ]]; then
        echo -e "${G}● BẬT${N} │ $METHOD"
    else
        echo -e "${Y}○ TẮT${N} │ $METHOD"
    fi
}

case "$1" in
    telex)
        mkdir -p "$CONFIG_DIR"
        echo "telex" > "$METHOD_FILE"
        fcitx5-remote -r 2>/dev/null || fcitx5 -r 2>/dev/null
        show_status
        ;;
    vni)
        mkdir -p "$CONFIG_DIR"
        echo "vni" > "$METHOD_FILE"
        fcitx5-remote -r 2>/dev/null || fcitx5 -r 2>/dev/null
        show_status
        ;;
    on)
        fcitx5-remote -o 2>/dev/null
        show_status
        ;;
    off)
        fcitx5-remote -c 2>/dev/null
        show_status
        ;;
    toggle|"")
        fcitx5-remote -t 2>/dev/null
        show_status
        ;;
    status)
        show_status
        ;;
    version|-v|--version)
        echo "Gõ Nhanh v$VERSION"
        ;;
    update)
        echo -e "${B}[*]${N} Đang cập nhật..."
        curl -fsSL https://raw.githubusercontent.com/khaphanspace/gonhanh.org/main/scripts/install-linux.sh | bash
        ;;
    uninstall)
        echo -e "${Y}[!]${N} Gỡ cài đặt Gõ Nhanh..."
        rm -f ~/.local/lib/fcitx5/gonhanh.so ~/.local/lib/libgonhanh_core.so
        rm -f ~/.local/share/fcitx5/addon/gonhanh.conf ~/.local/share/fcitx5/inputmethod/gonhanh.conf
        rm -rf ~/.local/share/gonhanh ~/.config/gonhanh
        rm -f ~/.local/bin/gn
        fcitx5 -r 2>/dev/null || true
        echo -e "${G}[✓]${N} Đã gỡ cài đặt"
        ;;
    diagnose)
        # System diagnostic command
        echo "=== Gõ Nhanh Diagnostics ==="
        echo ""

        # 1. Check Fcitx5
        if command -v fcitx5 &> /dev/null; then
            success "Fcitx5 installed: $(fcitx5 --version 2>/dev/null | head -1)"
        else
            error "Fcitx5 not installed"
            info "Install: sudo apt install fcitx5 fcitx5-configtool"
        fi

        # 2. Check addon
        if [ -f "$HOME/.local/lib/fcitx5/gonhanh.so" ]; then
            success "Gõ Nhanh addon installed"
        else
            error "Addon not found"
            info "Reinstall: cd platforms/linux && ./scripts/install.sh"
        fi

        # 3. Check core library
        if [ -f "$HOME/.local/lib/libgonhanh_core.so" ]; then
            success "Core library found"
        else
            error "Core library not found"
        fi

        # 4. Check environment variables
        echo ""
        info "Environment variables:"
        local env_ok=true
        for var in GTK_IM_MODULE QT_IM_MODULE XMODIFIERS; do
            if [ "${!var}" = "fcitx" ] || [ "${!var}" = "@im=fcitx" ]; then
                success "$var=${!var}"
            else
                warning "$var not set (run: gn fix-env)"
                env_ok=false
            fi
        done

        # 5. Check Fcitx5 status
        echo ""
        if pgrep fcitx5 > /dev/null; then
            success "Fcitx5 is running"
            if fcitx5-remote &> /dev/null; then
                success "Fcitx5 is responsive"
            else
                warning "Fcitx5 not responding"
            fi
        else
            error "Fcitx5 is not running"
            info "Start: fcitx5 -d"
        fi

        # 6. Desktop-specific checks
        echo ""
        local desktop="${XDG_CURRENT_DESKTOP:-Unknown}"
        local session="${XDG_SESSION_TYPE:-Unknown}"
        info "Desktop: $desktop, Session: $session"

        if [[ "$desktop" == *"GNOME"* ]] && [[ "$session" == "wayland" ]]; then
            if [ -d "$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
               [ -d "/usr/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
               dpkg -l 2>/dev/null | grep -q gnome-shell-extension-kimpanel; then
                success "KIMPanel extension installed"
            else
                warning "KIMPanel missing (run: gn fix-gnome)"
            fi
        fi

        # 7. Recommendations
        echo ""
        info "Recommendations:"
        [ "$env_ok" = false ] && echo "  • Run: gn fix-env"
        ! pgrep fcitx5 > /dev/null && echo "  • Log out and log in again"
        ;;
    fix-env)
        # Fix environment variables
        info "Fixing environment variables..."
        local env_dir="$HOME/.config/environment.d"
        local env_file="$env_dir/90-gonhanh.conf"

        mkdir -p "$env_dir"

        # Backup if exists
        if [ -f "$env_file" ]; then
            local backup="$env_file.backup.$(date +%Y%m%d-%H%M%S)"
            cp "$env_file" "$backup"
            info "Backed up to: $backup"
        fi

        # Create config
        cat > "$env_file" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF
        chmod 644 "$env_file"

        success "Environment configured at: $env_file"
        echo ""
        warning "Please log out and log in for changes to take effect"
        ;;
    fix-gnome)
        # Fix GNOME Wayland KIMPanel
        local desktop="${XDG_CURRENT_DESKTOP:-Unknown}"
        local session="${XDG_SESSION_TYPE:-Unknown}"

        if [[ "$desktop" != *"GNOME"* ]]; then
            info "Not running GNOME, skipping"
            exit 0
        fi

        if [[ "$session" != "wayland" ]]; then
            info "Not using Wayland, KIMPanel not needed"
            exit 0
        fi

        # Check if already installed
        if [ -d "$HOME/.local/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
           [ -d "/usr/share/gnome-shell/extensions/kimpanel@kde.org" ] || \
           dpkg -l 2>/dev/null | grep -q gnome-shell-extension-kimpanel; then
            success "KIMPanel already installed"
            info "Enable it: Extensions app → Input Method Panel → ON"
            info "Or run: gnome-extensions enable kimpanel@kde.org"
            exit 0
        fi

        # Install KIMPanel
        info "Installing KIMPanel extension for GNOME Wayland..."
        if sudo apt update && sudo apt install -y gnome-shell-extension-kimpanel; then
            success "KIMPanel installed"
            echo ""
            info "Next steps:"
            echo "  1. Log out and log in again"
            echo "  2. Open Extensions app (gnome-extensions-app)"
            echo "  3. Enable 'Input Method Panel'"
            echo ""
            info "Or run: gnome-extensions enable kimpanel@kde.org"
        else
            error "Failed to install KIMPanel"
            info "Try manually: sudo apt install gnome-shell-extension-kimpanel"
        fi
        ;;
    help|-h|--help|*)
        echo -e "${B}Gõ Nhanh${N} v$VERSION - Vietnamese Input Method"
        echo ""
        echo "Cách dùng: gn [lệnh]"
        echo ""
        echo "Lệnh cơ bản:"
        echo "  (không có)   Toggle bật/tắt"
        echo "  on           Bật tiếng Việt"
        echo "  off          Tắt tiếng Việt"
        echo "  telex        Chuyển sang Telex"
        echo "  vni          Chuyển sang VNI"
        echo "  status       Xem trạng thái"
        echo ""
        echo "Chẩn đoán & sửa lỗi:"
        echo "  diagnose     Kiểm tra cấu hình hệ thống"
        echo "  fix-env      Sửa biến môi trường"
        echo "  fix-gnome    Cài KIMPanel cho GNOME Wayland"
        echo ""
        echo "Quản lý:"
        echo "  update       Cập nhật phiên bản mới"
        echo "  uninstall    Gỡ cài đặt"
        echo "  version      Xem phiên bản"
        echo "  help         Hiển thị trợ giúp"
        ;;
esac
