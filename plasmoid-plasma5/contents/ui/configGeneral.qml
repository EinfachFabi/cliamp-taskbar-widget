import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    id: configPage

    property alias cfg_pollInterval: pollIntervalSpin.value
    property alias cfg_showTrackInPanel: showTrackCheck.checked
    property alias cfg_panelTrackMaxWidth: maxWidthSpin.value
    property alias cfg_showPanelControls: showControlsCheck.checked
    property alias cfg_preferredTerminal: terminalCombo.currentValue
    property alias cfg_defaultProvider: providerCombo.currentValue
    property double cfg_volumeStepDb: 1.5

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Taskbar / Panel Appearance"
    }

    QQC2.CheckBox {
        id: showTrackCheck
        Kirigami.FormData.label: "Track Label:"
        text: "Show current track title next to icon (Panel only, not System Tray)"
    }

    QQC2.SpinBox {
        id: maxWidthSpin
        Kirigami.FormData.label: "Max Label Width (px):"
        from: 60
        to: 400
        stepSize: 10
        enabled: showTrackCheck.checked
    }

    QQC2.CheckBox {
        id: showControlsCheck
        Kirigami.FormData.label: "Inline Controls:"
        text: "Show Prev / Play / Next buttons directly in the panel"
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: "Behavior & Integration"
    }

    QQC2.SpinBox {
        id: pollIntervalSpin
        Kirigami.FormData.label: "Status Poll Interval (ms):"
        from: 500
        to: 5000
        stepSize: 250
    }

    QQC2.ComboBox {
        id: terminalCombo
        Kirigami.FormData.label: "Terminal Emulator (for TUI):"
        textRole: "text"
        valueRole: "value"
        model: [
            { text: "Auto-detect (Recommended)", value: "auto" },
            { text: "KDE Konsole", value: "konsole" },
            { text: "Alacritty", value: "alacritty" },
            { text: "Kitty", value: "kitty" },
            { text: "Ghostty", value: "ghostty" },
            { text: "WezTerm", value: "wezterm" },
            { text: "Foot", value: "foot" }
        ]
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(configPage.cfg_preferredTerminal))
    }

    QQC2.ComboBox {
        id: providerCombo
        Kirigami.FormData.label: "Default Music Source:"
        textRole: "text"
        valueRole: "value"
        model: [
            { text: "cliamp Radio", value: "cliamp" },
            { text: "Local Playlists", value: "local" },
            { text: "Internet Radio", value: "radio" },
            { text: "Podcasts", value: "podcast" },
            { text: "Spotify", value: "spotify" },
            { text: "YouTube Music", value: "ytmusic" },
            { text: "SoundCloud", value: "soundcloud" }
        ]
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(configPage.cfg_defaultProvider))
    }
}
