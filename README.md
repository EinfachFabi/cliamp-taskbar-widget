# cliamp-taskbar-widget — Native KDE Plasma Taskbar Integration for `cliamp`

[![KDE Plasma 6](https://img.shields.io/badge/KDE_Plasma-6.0%2B%20%7C%205.27%2B-1d99f3?logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![cliamp](https://img.shields.io/badge/cliamp-v2.0%2B-f9e2af)](https://github.com/bjarneo/cliamp)
[![License: MIT](https://img.shields.io/badge/License-MIT-a6e3a1.svg)](LICENSE)

A native **KDE Plasma Taskbar Widget (Plasmoid) & CLI Controller** for the [**cliamp**](https://github.com/bjarneo/cliamp) retro terminal music player.
Supports both **KDE Plasma 6** and **KDE Plasma 5** across all major Linux distributions (Arch, Manjaro, CachyOS, EndeavourOS, Debian, Ubuntu/Kubuntu, KDE neon, Fedora, Nobara, openSUSE Tumbleweed/Leap, and more).

---

## ✨ Features

* **Clean Taskbar / System Tray Integration (Compact View)**:
  * **Zero-overlap icon mode by default**: Fits cleanly into both the KDE Panel and the System Tray with a live playback status indicator dot (`green` = playing, `yellow` = paused, `blue` = idle, `gray` = offline)
  * **Optional Expanded Panel Bar**: Optionally show the current song title (`Artist – Title`) and inline transport buttons (`⏮`, `▶/⏸`, `⏭`) when placed directly in a wide horizontal panel
  * **Mouse Wheel Control**: Scroll up/down over the taskbar icon to adjust `cliamp` volume in `dB`
  * **Middle-Click**: Instant Play/Pause toggle (automatically starts the background daemon if `cliamp` is not running)
  * **Right-Click Context Menu**: Quick actions for Play/Pause, Next/Previous, Start/Stop Background Daemon, Open in Terminal (TUI), and Provider Setup (`cliamp setup`)
* **Full Popup Player Window (Full Representation)**:
  * **Now Playing & Transport Card**: Track title, artist, active playlist/stream badge, interactive seek bar, Shuffle, Repeat (`Off` / `All` / `One`), and Volume slider (`-30 dB` to `+6 dB`)
  * **Background Daemon & Terminal Switching**: Start or stop `cliamp --daemon` (headless background mode) with one click, or switch seamlessly into the interactive Terminal UI (`konsole`, `alacritty`, `kitty`, `ghostty`, `wezterm`, `foot`, etc.)
  * **Tab 1 – Queue**: Browse the active track queue and jump to any track with a single click
  * **Tab 2 – Sources (3 Organized Sub-Categories + Station Browser)**:
    * **Playlists**: One-click playback for all saved local playlists (`Favorites`, `Recently Played`, custom playlists)
    * **Radio & URL**: Built-in `cliamp Radio`, `Internet Radio`, and `Podcasts` with a **Browse** view to pick individual stations/channels, plus a direct **Stream / YouTube URL** player
    * **Cloud**: One-click start and playlist browser for `Spotify`, `YouTube Music`, `SoundCloud`, `Bandcamp`, `Tidal`, `Qobuz`, `Navidrome / Subsonic`, `Jellyfin`, and `Plex` + one-click button to launch `cliamp setup`
  * **Tab 3 – Equalizer**: All 15 `cliamp` EQ presets (`Flat`, `Rock`, `Pop`, `Jazz`, `Classical`, `Bass Boost`, `Treble Boost`, `Electronic`, `Vocal`, `Acoustic`, `Late Night`, `Hip-Hop`, `R&B`, `Loudness`, `Custom`) + 10 interactive graphic equalizer bands (`31 Hz` – `16 kHz`)
  * **Tab 4 – Audio**: Stereo/Mono toggle, playback speed (`0.75x` – `2.0x`), and quick seek (`±10s`, `±30s`)

---

## 🚀 Quick Installation (All KDE Linux Distros)

The included [`install.sh`](install.sh) script automatically detects your Linux distribution and KDE Plasma version (Plasma 6 or Plasma 5). If `cliamp` is not yet installed, it will automatically install it for you.

```bash
git clone https://github.com/EinfachFabi/cliamp-taskbar-widget.git
cd cliamp-taskbar-widget
./install.sh
```

### Optional Installer Flags

```bash
# Install and enable the systemd user background daemon on login:
./install.sh --enable-service

# Install and immediately reload the KDE Plasma panel:
./install.sh --reload-plasma
```

---

## 📌 Adding the Widget to Your KDE Taskbar

### Option A: Directly in the KDE Panel / Taskbar
1. **Right-click** on your KDE Panel ➔ **"Add or Manage Widgets…"**
2. Search for **`cliamp`** (**`cliamp Controller`**)
3. Drag the widget to your desired position on the panel.

### Option B: Inside the System Tray
1. **Right-click** the small arrow `▲` in your System Tray ➔ **"Configure System Tray…"**
2. Under *Entries*, find **"cliamp Controller"** and set visibility to **"Always shown"**.

---

## ⌨️ CLI Controller & Global Shortcuts (`cliamp-kde-ctl`)

The installer places [`cliamp-kde-ctl`](bin/cliamp-kde-ctl) into `~/.local/bin/cliamp-kde-ctl`. You can bind these commands to global keyboard shortcuts in *KDE System Settings ➔ Shortcuts*:

```bash
cliamp-kde-ctl toggle                      # Play/Pause (auto-starts daemon if offline)
cliamp-kde-ctl next                        # Next track
cliamp-kde-ctl prev                        # Previous track
cliamp-kde-ctl volume-step 1.5             # Volume +1.5 dB
cliamp-kde-ctl volume-step -1.5            # Volume -1.5 dB
cliamp-kde-ctl start-daemon                # Start headless background daemon
cliamp-kde-ctl stop-daemon                 # Stop background daemon
cliamp-kde-ctl open-terminal               # Open cliamp TUI in terminal
cliamp-kde-ctl open-setup                  # Open 'cliamp setup' wizard in terminal
cliamp-kde-ctl load-playlist "Favorites"   # Load & play a local playlist
cliamp-kde-ctl load-provider cliamp        # Start cliamp Radio
cliamp-kde-ctl eq "Bass Boost"             # Switch Equalizer preset
cliamp-kde-ctl status                      # Print current playback status as JSON
```

---

## 📦 Building `.plasmoid` Release Packages

To build distributable `.plasmoid` archives for GitHub Releases or the KDE Store:

```bash
./scripts/build-plasmoid.sh
```
Outputs:
* `dist/cliamp-kde-plasma6.plasmoid` (for KDE Plasma 6)
* `dist/cliamp-kde-plasma5.plasmoid` (for KDE Plasma 5)

---

## 🗑️ Uninstallation

```bash
./uninstall.sh
```

---

## 📄 License

Released under the [MIT License](LICENSE).
