#!/usr/bin/env bash
# ==============================================================================
# cliamp-taskbar-widget — Uninstaller
# Removes the KDE Plasma Widget, helper script, icon, systemd service,
# and resets all saved cliamp-kde & widget settings back to defaults.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }

echo -e "${BOLD}Uninstalling cliamp KDE Plasma Taskbar Integration...${NC}"

# 1. Reset saved volume, EQ, visualizer, and theme settings before stopping daemon
if command -v cliamp-kde-ctl >/dev/null 2>&1; then
    cliamp-kde-ctl reset-settings >/dev/null 2>&1 || true
    cliamp-kde-ctl stop-daemon >/dev/null 2>&1 || true
fi

# 2. Explicitly remove cliamp-kde state & log files and reset config.toml overrides
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/cliamp"
rm -f "$CONFIG_DIR/kde-state.json" "$CONFIG_DIR/kde-daemon.log"

if [[ -f "$CONFIG_DIR/config.toml" ]] && command -v python3 >/dev/null 2>&1; then
    python3 - "$CONFIG_DIR/config.toml" <<'PY' || true
import re, sys
from pathlib import Path

p = Path(sys.argv[1])
if p.is_file():
    lines = p.read_text(encoding="utf-8").splitlines()
    cleaned = [
        ln for ln in lines
        if not re.match(r"^\s*(theme|visualizer)\s*=", ln)
    ]
    text = "\n".join(cleaned).strip()
    if text:
        p.write_text(text + "\n", encoding="utf-8")
    else:
        p.unlink()
PY
fi
success "Saved cliamp-kde settings (volume, mute state, visualizer, theme) reset."

# 3. Stop and disable systemd service if active
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now cliamp-daemon.service >/dev/null 2>&1 || true
    rm -f "$HOME/.config/systemd/user/cliamp-daemon.service"
    systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

# 4. Reset KDE Plasma applet configuration entries in plasma-org.kde.plasma.desktop-appletsrc
APPLETS_RC="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
if [[ -f "$APPLETS_RC" ]] && command -v python3 >/dev/null 2>&1; then
    python3 - "$APPLETS_RC" <<'PY' || true
import re, sys
from pathlib import Path

rc_path = Path(sys.argv[1])
if rc_path.is_file():
    content = rc_path.read_text(encoding="utf-8")
    blocks = re.split(r"(?m)(?=^\[)", content)
    target_prefixes = []
    for b in blocks:
        if "plugin=org.kde.plasma.cliamp" in b:
            m = re.match(r"^(\[Containments\]\[\d+\]\[Applets\]\[\d+\])", b)
            if m:
                target_prefixes.append(m.group(1) + "[Configuration]")
    if target_prefixes:
        kept = [
            b for b in blocks
            if not any(b.startswith(pref) for pref in target_prefixes)
        ]
        rc_path.write_text("".join(kept), encoding="utf-8")
PY
    success "KDE Plasma widget configuration reset."
fi

# 5. Remove KDE Plasmoid package
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.cliamp >/dev/null 2>&1 || true
elif command -v kpackagetool5 >/dev/null 2>&1; then
    kpackagetool5 --type Plasma/Applet --remove org.kde.plasma.cliamp >/dev/null 2>&1 || true
fi
rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.cliamp"
success "KDE Plasma Widget (org.kde.plasma.cliamp) removed."

# 6. Remove helper script & icon
rm -f "$HOME/.local/bin/cliamp-kde-ctl"
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/cliamp.svg"
success "cliamp-kde-ctl and icon removed."

echo -e "${GREEN}${BOLD}Uninstallation and settings reset complete!${NC} (Note: cliamp itself was not removed.)"
