#!/usr/bin/env bash
# ==============================================================================
# cliamp-kde — Cross-Distro Installer for the cliamp KDE Plasma Taskbar Widget
# Supports: Arch/Manjaro/CachyOS, Debian/Ubuntu/Kubuntu/KDE Neon, Fedora/Nobara,
#           openSUSE Tumbleweed/Leap, Void, and generic Linux systems with KDE.
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; }

ENABLE_SERVICE=false
RELOAD_PLASMA=false
SKIP_DEPS=false
FORCE_PLASMA_VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --enable-service)
            ENABLE_SERVICE=true
            shift
            ;;
        --reload-plasma)
            RELOAD_PLASMA=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --plasma5)
            FORCE_PLASMA_VERSION="5"
            shift
            ;;
        --plasma6)
            FORCE_PLASMA_VERSION="6"
            shift
            ;;
        -h|--help)
            cat << 'EOF'
Usage: ./install.sh [OPTIONS]

Options:
  --enable-service   Enable and start the systemd user daemon (cliamp-daemon.service)
  --reload-plasma    Restart KDE Plasma shell (plasmashell --replace) after installation
  --skip-deps        Skip automatic package manager dependency check
  --plasma6          Force installation of the KDE Plasma 6 widget
  --plasma5          Force installation of the KDE Plasma 5 widget
  -h, --help         Show this help message
EOF
            exit 0
            ;;
        *)
            warn "Unknown option: $1"
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}==============================================================${NC}"
echo -e "${BOLD}   cliamp KDE Plasma Taskbar Integration — Installer          ${NC}"
echo -e "${BOLD}==============================================================${NC}"

# ------------------------------------------------------------------------------
# 1. Detect Linux Distribution & Check Dependencies
# ------------------------------------------------------------------------------
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${ID:-unknown}:${ID_LIKE:-}"
    else
        echo "unknown:"
    fi
}

install_system_dependencies() {
    if [[ "$SKIP_DEPS" == "true" ]]; then
        info "Skipping package manager check (--skip-deps)."
        return 0
    fi

    if command -v python3 >/dev/null 2>&1 && (command -v kpackagetool6 >/dev/null 2>&1 || command -v kpackagetool5 >/dev/null 2>&1); then
        success "All required KDE Plasma & Python dependencies are present."
        return 0
    fi

    local distro_info
    distro_info="$(detect_distro)"
    info "Checking system dependencies for distro (${distro_info})..."

    if command -v pacman >/dev/null 2>&1; then
        local missing_pkgs=()
        command -v python3 >/dev/null 2>&1 || missing_pkgs+=("python")
        command -v curl >/dev/null 2>&1 || missing_pkgs+=("curl")
        command -v kpackagetool6 >/dev/null 2>&1 || missing_pkgs+=("kpackage" "plasma5support")
        if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            info "Installing missing packages via pacman: ${missing_pkgs[*]}"
            sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        local missing_pkgs=()
        command -v python3 >/dev/null 2>&1 || missing_pkgs+=("python3")
        command -v curl >/dev/null 2>&1 || missing_pkgs+=("curl")
        if ! command -v kpackagetool6 >/dev/null 2>&1 && ! command -v kpackagetool5 >/dev/null 2>&1; then
            missing_pkgs+=("kpackagetool6" "libasound2-plugins")
        fi
        if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            info "Installing missing packages via apt: ${missing_pkgs[*]}"
            sudo apt-get update && sudo apt-get install -y "${missing_pkgs[@]}" || true
        fi
    elif command -v dnf >/dev/null 2>&1; then
        local missing_pkgs=()
        command -v python3 >/dev/null 2>&1 || missing_pkgs+=("python3")
        command -v curl >/dev/null 2>&1 || missing_pkgs+=("curl")
        if ! command -v kpackagetool6 >/dev/null 2>&1 && ! command -v kpackagetool5 >/dev/null 2>&1; then
            missing_pkgs+=("kf6-kpackage" "plasma-workspace" "pipewire-alsa")
        fi
        if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            info "Installing missing packages via dnf: ${missing_pkgs[*]}"
            sudo dnf install -y "${missing_pkgs[@]}" || true
        fi
    elif command -v zypper >/dev/null 2>&1; then
        local missing_pkgs=()
        command -v python3 >/dev/null 2>&1 || missing_pkgs+=("python3")
        command -v curl >/dev/null 2>&1 || missing_pkgs+=("curl")
        if ! command -v kpackagetool6 >/dev/null 2>&1 && ! command -v kpackagetool5 >/dev/null 2>&1; then
            missing_pkgs+=("kf6-kpackage" "alsa-plugins")
        fi
        if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
            info "Installing missing packages via zypper: ${missing_pkgs[*]}"
            sudo zypper install -y "${missing_pkgs[@]}" || true
        fi
    else
        warn "Unknown package manager — please ensure python3 and KDE Plasma are installed."
    fi
}

# ------------------------------------------------------------------------------
# 2. Check / Install cliamp Binary
# ------------------------------------------------------------------------------
ensure_cliamp_installed() {
    export PATH="$HOME/.local/bin:$PATH"
    if command -v cliamp >/dev/null 2>&1; then
        local ver
        ver="$(cliamp --version 2>/dev/null || echo 'installed')"
        success "cliamp is already installed (${ver})."
        return 0
    fi

    info "cliamp not found on system. Installing cliamp..."

    if command -v yay >/dev/null 2>&1; then
        info "AUR helper 'yay' found — installing cliamp-bin..."
        if yay -S --needed --noconfirm cliamp-bin || yay -S --needed --noconfirm cliamp; then
            success "cliamp installed successfully via AUR."
            return 0
        fi
    elif command -v paru >/dev/null 2>&1; then
        info "AUR helper 'paru' found — installing cliamp-bin..."
        if paru -S --needed --noconfirm cliamp-bin || paru -S --needed --noconfirm cliamp; then
            success "cliamp installed successfully via AUR."
            return 0
        fi
    fi

    info "Downloading latest cliamp release from GitHub..."
    mkdir -p "$HOME/.local/bin"
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64) arch_tag="amd64" ;;
        aarch64|arm64) arch_tag="arm64" ;;
        *)
            error "Unsupported architecture for binary download: $arch"
            return 1
            ;;
    esac

    local download_url="https://github.com/bjarneo/cliamp/releases/latest/download/cliamp-linux-${arch_tag}"
    if curl -fsSL "$download_url" -o "$HOME/.local/bin/cliamp"; then
        chmod +x "$HOME/.local/bin/cliamp"
        success "cliamp installed to ~/.local/bin/cliamp."
    else
        warn "Direct binary download failed. Running official cliamp installer script..."
        curl -fsSL https://raw.githubusercontent.com/bjarneo/cliamp/main/install.sh | sh
    fi
}

# ------------------------------------------------------------------------------
# 3. Install Helper CLI & Icons
# ------------------------------------------------------------------------------
install_cli_and_icons() {
    info "Installing controller script (cliamp-kde-ctl) & icons..."
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"

    cp "$SCRIPT_DIR/bin/cliamp-kde-ctl" "$HOME/.local/bin/cliamp-kde-ctl"
    chmod +x "$HOME/.local/bin/cliamp-kde-ctl"

    cp "$SCRIPT_DIR/plasmoid/contents/images/cliamp.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/cliamp.svg"

    cp "$SCRIPT_DIR/bin/cliamp-kde-ctl" "$SCRIPT_DIR/plasmoid/contents/scripts/cliamp-kde-ctl"
    cp "$SCRIPT_DIR/bin/cliamp-kde-ctl" "$SCRIPT_DIR/plasmoid-plasma5/contents/scripts/cliamp-kde-ctl"
    chmod +x "$SCRIPT_DIR/plasmoid/contents/scripts/cliamp-kde-ctl"
    chmod +x "$SCRIPT_DIR/plasmoid-plasma5/contents/scripts/cliamp-kde-ctl"

    success "cliamp-kde-ctl installed to ~/.local/bin/cliamp-kde-ctl"
}

# ------------------------------------------------------------------------------
# 4. Install KDE Plasma Widget (Plasmoid) for Plasma 6 or Plasma 5
# ------------------------------------------------------------------------------
detect_plasma_version() {
    if [[ -n "$FORCE_PLASMA_VERSION" ]]; then
        echo "$FORCE_PLASMA_VERSION"
        return 0
    fi
    if command -v kpackagetool6 >/dev/null 2>&1; then
        echo "6"
    elif command -v kpackagetool5 >/dev/null 2>&1; then
        echo "5"
    else
        echo "6"
    fi
}

cleanup_duplicate_systray_entry() {
    local appletsrc="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    if [[ ! -f "$appletsrc" ]]; then
        return 0
    fi
    python3 - "$appletsrc" << 'EOF' || true
import re
import sys

path = sys.argv[1]
try:
    text = open(path, "r", encoding="utf-8").read()
except Exception:
    sys.exit(0)

# Remove nested systemtray applet sections for org.kde.plasma.cliamp
# e.g. [Containments][23][Applets][28][Applets][57] where plugin=org.kde.plasma.cliamp
blocks = re.split(r"(?m)(?=^\[)", text)
kept = []
removed_prefixes = set()

for b in blocks:
    m = re.match(r"^(\[Containments\]\[\d+\]\[Applets\]\[\d+\]\[Applets\]\[\d+\])\s*\n", b)
    if m and "plugin=org.kde.plasma.cliamp" in b:
        removed_prefixes.add(m.group(1))
        continue
    kept.append(b)

final_blocks = []
for b in kept:
    skip = False
    for pref in removed_prefixes:
        if b.startswith(pref):
            skip = True
            break
    if not skip:
        # Also remove org.kde.plasma.cliamp from systemtray extraItems / knownItems
        b = re.sub(r",org\.kde\.plasma\.cliamp\b", "", b)
        b = re.sub(r"\borg\.kde\.plasma\.cliamp,", "", b)
        final_blocks.append(b)

new_text = "".join(final_blocks)
if new_text != text:
    open(path, "w", encoding="utf-8").write(new_text)
EOF
}

install_plasmoid() {
    local plasma_ver
    plasma_ver="$(detect_plasma_version)"
    local src_dir="$SCRIPT_DIR/plasmoid"
    local kpkg_bin="kpackagetool6"

    if [[ "$plasma_ver" == "5" ]]; then
        src_dir="$SCRIPT_DIR/plasmoid-plasma5"
        kpkg_bin="kpackagetool5"
    fi

    info "Detected KDE Plasma version: Plasma ${plasma_ver}"
    local target_dir="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.cliamp"

    if command -v "$kpkg_bin" >/dev/null 2>&1; then
        if [[ -d "$target_dir" ]]; then
            info "Upgrading existing KDE widget via ${kpkg_bin}..."
            "$kpkg_bin" --type Plasma/Applet --upgrade "$src_dir" >/dev/null 2>&1 || {
                rm -rf "$target_dir"
                "$kpkg_bin" --type Plasma/Applet --install "$src_dir" >/dev/null 2>&1
            }
        else
            info "Installing KDE widget via ${kpkg_bin}..."
            "$kpkg_bin" --type Plasma/Applet --install "$src_dir" >/dev/null 2>&1 || {
                mkdir -p "$(dirname "$target_dir")"
                cp -r "$src_dir" "$target_dir"
            }
        fi
    else
        info "Copying Plasmoid files directly to ${target_dir}..."
        rm -rf "$target_dir"
        mkdir -p "$(dirname "$target_dir")"
        cp -r "$src_dir" "$target_dir"
    fi

    if [[ -f "$target_dir/contents/scripts/cliamp-kde-ctl" ]]; then
        chmod +x "$target_dir/contents/scripts/cliamp-kde-ctl"
    fi

    cleanup_duplicate_systray_entry

    success "KDE Plasma Widget 'org.kde.plasma.cliamp' installed successfully!"
}

# ------------------------------------------------------------------------------
# 5. Install Optional systemd User Service
# ------------------------------------------------------------------------------
install_systemd_service() {
    local systemd_dir="$HOME/.config/systemd/user"
    mkdir -p "$systemd_dir"
    cp "$SCRIPT_DIR/systemd/cliamp-daemon.service" "$systemd_dir/cliamp-daemon.service"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload >/dev/null 2>&1 || true
        if [[ "$ENABLE_SERVICE" == "true" ]]; then
            info "Enabling and starting cliamp-daemon.service..."
            systemctl --user enable --now cliamp-daemon.service || true
            success "systemd user service cliamp-daemon.service enabled!"
        else
            info "systemd unit installed at ~/.config/systemd/user/cliamp-daemon.service"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Run Installation Steps
# ------------------------------------------------------------------------------
install_system_dependencies
ensure_cliamp_installed
install_cli_and_icons
install_plasmoid
install_systemd_service

if [[ "$RELOAD_PLASMA" == "true" ]]; then
    info "Restarting plasmashell to reload widgets..."
    if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
        systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1 || true
    elif command -v kquitapp6 >/dev/null 2>&1; then
        kquitapp6 plasmashell >/dev/null 2>&1 || true
        kstart plasmashell >/dev/null 2>&1 &
    elif command -v plasmashell >/dev/null 2>&1; then
        nohup plasmashell --replace >/dev/null 2>&1 &
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}==============================================================${NC}"
echo -e "${GREEN}${BOLD}   Installation completed successfully!                       ${NC}"
echo -e "${GREEN}${BOLD}==============================================================${NC}"
echo ""
echo -e "${BOLD}How to add the widget to your KDE Taskbar:${NC}"
echo -e "  1. Right-click on your KDE Panel -> ${BOLD}'Add or Manage Widgets…'${NC}"
echo -e "  2. Search for ${BOLD}'cliamp'${NC} (${BOLD}cliamp Controller${NC})"
echo -e "  3. Drag the widget onto your panel."
echo ""
echo -e "${BOLD}Useful CLI commands:${NC}"
echo -e "  • ${BOLD}cliamp-kde-ctl toggle${NC}        (Play/Pause, auto-starts daemon if offline)"
echo -e "  • ${BOLD}cliamp-kde-ctl start-daemon${NC}  (Start headless background daemon)"
echo -e "  • ${BOLD}cliamp-kde-ctl open-terminal${NC} (Open interactive TUI in terminal)"
echo ""
