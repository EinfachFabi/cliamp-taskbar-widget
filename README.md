# cliamp-taskbar-widget

Native KDE Plasma taskbar widget and controller for the [**cliamp**](https://github.com/bjarneo/cliamp) terminal music player. Supports **KDE Plasma 6** and **Plasma 5** on all Linux distributions.

```bash
git clone https://github.com/EinfachFabi/cliamp-taskbar-widget.git
cd cliamp-taskbar-widget
./install.sh
```

To reload your taskbar immediately after installation:
```bash
./install.sh --reload-plasma
```

---

## Requirements

- **KDE Plasma 6** or **Plasma 5**
- **cliamp** (the installer automatically installs it if not already present)
- Python 3

---

## What it does

| Area | Features |
|------|----------|
| **Taskbar / Panel** | Live visualizer, current track title, status dot, zero widget overlap |
| **Mouse Controls** | Left-click opens player · Middle-click toggles Play/Pause · Scroll wheel changes volume (dB) · Right-click opens menu & settings |
| **Popup Player** | Transport controls, seek bar, queue browser, local playlists, radio, cloud sources |
| **Audio & EQ** | 10-band graphic equalizer with 15 presets, stereo/mono switch, playback speed (0.75x–2.0x), quick seek |
| **Volume Memory** | Remembers volume persistently; unmuting restores your exact previous volume |

---

## How to Add & Configure the Widget

1. Right-click on your KDE panel ➔ **Add or Manage Widgets…**
2. Search for **cliamp** (*cliamp Controller*)
3. Drag the widget onto your panel or into the System Tray.

### Widget Settings

Right-click the widget ➔ **Configure cliamp Controller…**:
- **Track Label**: Toggle current song title display next to the icon in the panel (with adjustable max width)
- **Inline Controls**: Toggle dedicated **⏮ / ▶/⏸ / ⏭** buttons directly inside your taskbar panel
- **Terminal Emulator**: Select which terminal launches the interactive cliamp TUI (*Konsole, Alacritty, Kitty, Ghostty, WezTerm, Foot, etc.*)
- **Default Music Source**: Choose your preferred startup source (*cliamp Radio, Local Playlists, Spotify, etc.*)

---

## Useful CLI Commands

The helper script `cliamp-kde-ctl` is installed to `~/.local/bin/` and can be bound to global KDE keyboard shortcuts:

```bash
cliamp-kde-ctl toggle                      # Play / Pause (starts background daemon if offline)
cliamp-kde-ctl next                        # Next track
cliamp-kde-ctl prev                        # Previous track
cliamp-kde-ctl toggle-mute                 # Mute / restore volume
cliamp-kde-ctl volume-step 1.5             # Volume +1.5 dB
cliamp-kde-ctl volume-step -1.5            # Volume -1.5 dB
cliamp-kde-ctl open-terminal               # Open cliamp TUI in your terminal
cliamp-kde-ctl start-daemon                # Start headless daemon in background
cliamp-kde-ctl stop-daemon                 # Stop daemon
```

---

## Uninstall

```bash
./uninstall.sh
```

Removes the widget, script, service, and resets all saved widget settings back to default.

---

## License

[MIT](LICENSE)
