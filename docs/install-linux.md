# Gõ Nhanh trên Linux

## Yêu cầu hệ thống

- **Ubuntu:** 22.04 LTS hoặc mới hơn (khuyến nghị)
- **Fcitx5:** Version 5.0+
- **Desktop:** GNOME, KDE, XFCE, hoặc tương tự

## Cài đặt nhanh

```bash
# Cài đặt Fcitx5 (nếu chưa có)
sudo apt install fcitx5 fcitx5-configtool

# Cài đặt Gõ Nhanh từ source
cd platforms/linux
./scripts/build.sh
./scripts/install.sh
```

**Lưu ý:** Script cài đặt sẽ tự động:
- Cấu hình biến môi trường IM tại `~/.config/environment.d/90-gonhanh.conf`
- Thiết lập `im-config` cho fcitx5
- Kiểm tra và cài đặt KIMPanel cho GNOME Wayland (nếu cần)

Đăng xuất và đăng nhập lại để hoàn tất.

---

## Sử dụng

| Phím tắt | Chức năng |
|----------|-----------|
| `Ctrl + Space` hoặc `Super + Space` | Bật/tắt tiếng Việt (tùy desktop) |

| Lệnh | Chức năng |
|------|-----------|
| `gn` | Toggle bật/tắt |
| `gn on` | Bật tiếng Việt |
| `gn off` | Tắt tiếng Việt |
| `gn vni` | Chuyển sang VNI |
| `gn telex` | Chuyển sang Telex |
| `gn status` | Xem trạng thái |
| `gn update` | Cập nhật phiên bản mới |
| `gn uninstall` | Gỡ cài đặt |
| `gn version` | Xem phiên bản |
| `gn help` | Hiển thị trợ giúp |

---

## Gỡ cài đặt

```bash
gn uninstall
```

---

## Xử lý sự cố

### Chẩn đoán tự động

```bash
gn diagnose
```

Script này sẽ kiểm tra:
- Fcitx5 có được cài đặt không
- Addon Gõ Nhanh
- Biến môi trường
- Desktop environment và phiên bản
- KIMPanel (cho GNOME Wayland)

### Các vấn đề thường gặp

**Lệnh `gn` không tìm thấy?**
```bash
# Thêm ~/.local/bin vào PATH
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

**Không gõ được tiếng Việt?**
```bash
# 1. Kiểm tra trạng thái
gn status

# 2. Sửa biến môi trường (nếu cần)
gn fix-env

# 3. Đăng xuất và đăng nhập lại
```

**Cửa sổ gợi ý không hiện (GNOME Wayland)?**
```bash
# Cài đặt KIMPanel extension
gn fix-gnome
# Sau đó bật extension trong Extensions app
```

**Thêm Gõ Nhanh vào Input Methods:**
```bash
fcitx5-configtool
```
→ Input Method → Add → Gõ Nhanh

**Kiểm tra biến môi trường:**
```bash
cat ~/.config/environment.d/90-gonhanh.conf
env | grep -E "(GTK|QT|XMODIFIERS).*fcitx"
```

---

## Biến môi trường

Gõ Nhanh tự động cấu hình các biến môi trường sau tại `~/.config/environment.d/90-gonhanh.conf`:

```bash
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
```

Nếu cần cấu hình thủ công hoặc khôi phục:
```bash
gn fix-env
```

## GNOME Wayland

Trên GNOME với Wayland, cần cài đặt **KIMPanel extension** để cửa sổ gợi ý hiển thị đúng vị trí:

```bash
# Tự động (khuyến nghị)
gn fix-gnome

# Hoặc thủ công
sudo apt install gnome-shell-extension-kimpanel
gnome-extensions enable kimpanel@kde.org
```

## Nâng cao

<details>
<summary>Cài Fcitx5 thủ công</summary>

```bash
# Ubuntu/Debian 22.04+
sudo apt install fcitx5 fcitx5-configtool

# Ubuntu 20.04 (cần PPA)
sudo add-apt-repository ppa:fcitx-team/stable
sudo apt update
sudo apt install fcitx5 fcitx5-configtool

# Fedora
sudo dnf install fcitx5 fcitx5-configtool

# Arch
sudo pacman -S fcitx5 fcitx5-configtool
```
</details>

<details>
<summary>Build từ source</summary>

Xem [platforms/linux/README.md](../platforms/linux/README.md)
</details>

<details>
<summary>Ứng dụng Electron (VS Code, Chrome, Discord)</summary>

Một số ứng dụng Electron trên Wayland cần flags đặc biệt:

Tạo `~/.config/electron-flags.conf`:
```
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--enable-wayland-ime
```

Hoặc thêm vào desktop file (ví dụ VS Code):
```bash
Exec=/usr/bin/code --enable-wayland-ime %F
```
</details>
