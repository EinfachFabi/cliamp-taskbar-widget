import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28
    Layout.preferredWidth: Kirigami.Units.gridUnit * 25
    Layout.preferredHeight: Kirigami.Units.gridUnit * 31

    collapseMarginsHint: true

    readonly property var eqFreqLabels: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    property int sourceCategoryIndex: 0 // 0 = Local Playlists, 1 = Radio & Streams, 2 = Cloud Services

    // Predefined Default Visualizer Theme
    function barColorForIndex(idx, level) {
        if (level > 0.75) return "#f38ba8";
        if (level > 0.48) return "#f9e2af";
        return idx % 3 === 0 ? "#89b4fa" : "#a6e3a1";
    }

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: 8

            Kirigami.Icon {
                source: Qt.resolvedUrl("../images/cliamp.svg")
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents3.Label {
                    text: "cliamp"
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                }

                RowLayout {
                    spacing: 5

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: {
                            if (!root.isRunning) return "#6c7086";
                            if (root.isMuted) return "#f38ba8";
                            if (root.playbackState === "playing") return "#a6e3a1";
                            if (root.playbackState === "paused") return "#f9e2af";
                            return "#89b4fa";
                        }
                    }

                    PlasmaComponents3.Label {
                        text: {
                            if (!root.cliampInstalled) return "Not installed";
                            if (!root.isRunning) return "Offline";
                            var st = root.playbackState === "playing" ? "Playing" : (root.playbackState === "paused" ? "Paused" : "Idle");
                            var md = root.runMode === "daemon" ? "Daemon" : "Terminal TUI";
                            return st + " • " + md;
                        }
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.8
                        elide: Text.ElideRight
                    }
                }
            }

            PlasmaComponents3.Button {
                icon.name: root.isRunning ? "process-stop" : "system-run"
                text: root.isRunning ? "Stop Daemon" : "Start Daemon"
                onClicked: root.runCtl("toggle-daemon", [])
                PlasmaComponents3.ToolTip {
                    text: root.isRunning ? "Stop background cliamp daemon" : "Start headless cliamp daemon in background"
                }
            }

            PlasmaComponents3.ToolButton {
                icon.name: "utilities-terminal"
                onClicked: root.runCtl("open-terminal", [Plasmoid.configuration.preferredTerminal || "auto"])
                PlasmaComponents3.ToolTip {
                    text: "Open interactive cliamp TUI in Terminal"
                }
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                onClicked: root.refreshDetails()
                PlasmaComponents3.ToolTip {
                    text: "Refresh player status & playlists"
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ============================================================
        // NOW PLAYING, LIVE VISUALIZER & TRANSPORT CARD
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: nowPlayingCol.implicitHeight + 16
            radius: 8
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

            ColumnLayout {
                id: nowPlayingCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Track Title, Artist & Badge
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 6
                        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.isStream ? "radio" : "audio-x-generic"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: {
                                if (!root.isRunning) return "Player Offline";
                                if (root.trackTitle !== "") return root.trackTitle;
                                return "No Track Loaded";
                            }
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: {
                                if (!root.isRunning) return "Press Play or choose a Source below to start";
                                var parts = [];
                                if (root.trackArtist !== "") parts.push(root.trackArtist);
                                if (root.activePlaylist !== "") parts.push(root.activePlaylist);
                                if (parts.length === 0) return root.isStream ? "Live Stream" : "Ready";
                                return parts.join(" • ");
                            }
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            opacity: 0.75
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        visible: root.isRunning && (root.isStream || root.trackTotal > 0)
                        radius: 4
                        color: root.isStream
                            ? Qt.rgba(0.95, 0.54, 0.65, 0.25)
                            : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                        implicitWidth: badgeLabel.implicitWidth + 10
                        implicitHeight: badgeLabel.implicitHeight + 4

                        PlasmaComponents3.Label {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: root.isStream
                                ? (root.trackTotal > 0 ? ("LIVE " + (root.trackIndex + 1) + "/" + root.trackTotal) : "LIVE")
                                : ((root.trackIndex + 1) + " / " + root.trackTotal)
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.9
                            font.bold: true
                        }
                    }
                }

                // Live Audio Spectrum Visualizer Box (Predefined Default Theme)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 6
                    color: "#181825"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 3

                        Repeater {
                            model: 20

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                readonly property int bandIdx: Math.floor(index / 2)
                                readonly property double rawBand: (root.visBands && root.visBands.length > bandIdx)
                                    ? Number(root.visBands[bandIdx])
                                    : 0.25
                                readonly property double idleWave: 0.18 + 0.14 * (Math.sin(index * 0.55) * 0.5 + 0.5)
                                readonly property double barLevel: (root.isRunning && root.playbackState === "playing")
                                    ? Math.min(1.0, Math.max(0.10, index % 2 === 0 ? rawBand : rawBand * 0.86))
                                    : idleWave

                                Rectangle {
                                    width: parent.width
                                    height: Math.max(3, Math.round(parent.height * parent.barLevel))
                                    anchors.bottom: parent.bottom
                                    radius: 1.5
                                    color: fullRoot.barColorForIndex(index, parent.barLevel)
                                    opacity: (root.isRunning && root.playbackState === "playing") ? 0.95 : 0.45

                                    Behavior on height {
                                        NumberAnimation { duration: 80 }
                                    }
                                }
                            }
                        }
                    }
                }

                // Seek / Progress Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.isRunning

                    PlasmaComponents3.Label {
                        text: root.formatTime(root.positionSec)
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.75
                    }

                    PlasmaComponents3.Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: root.durationSec > 0 ? root.durationSec : Math.max(100, root.positionSec + 10)
                        value: pressed ? value : root.positionSec
                        enabled: root.isSeekable && root.durationSec > 0
                        onMoved: {
                            if (root.isSeekable) {
                                root.runCtl("seek-abs", [String(Math.floor(value))]);
                            }
                        }
                    }

                    PlasmaComponents3.Label {
                        text: root.durationSec > 0 ? root.formatTime(root.durationSec) : (root.isStream ? "STREAM" : "--:--")
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.75
                    }
                }

                // Clean Centered Media Transport Controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-playlist-shuffle"
                        checked: root.isShuffle
                        checkable: true
                        enabled: root.isRunning
                        onClicked: root.runCtl("shuffle", [])
                        PlasmaComponents3.ToolTip { text: "Shuffle: " + (root.isShuffle ? "On" : "Off") }
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-skip-backward"
                        onClicked: root.runCtl("prev", [])
                        PlasmaComponents3.ToolTip { text: "Previous Track" }
                    }

                    PlasmaComponents3.Button {
                        icon.name: root.playbackState === "playing" ? "media-playback-pause" : "media-playback-start"
                        text: root.playbackState === "playing" ? "Pause" : "Play"
                        highlighted: true
                        onClicked: root.runCtl("toggle", [])
                        PlasmaComponents3.ToolTip {
                            text: root.isRunning
                                ? (root.playbackState === "playing" ? "Pause playback" : "Resume playback")
                                : "Start daemon & play"
                        }
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-playback-stop"
                        enabled: root.isRunning
                        onClicked: root.runCtl("stop", [])
                        PlasmaComponents3.ToolTip { text: "Stop Playback" }
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-skip-forward"
                        onClicked: root.runCtl("next", [])
                        PlasmaComponents3.ToolTip { text: "Next Track" }
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents3.ToolButton {
                        icon.name: root.repeatMode === "One" ? "media-playlist-repeat-song" : "media-playlist-repeat"
                        checked: root.repeatMode !== "Off"
                        checkable: true
                        enabled: root.isRunning
                        text: root.repeatMode === "One" ? "1" : (root.repeatMode === "All" ? "All" : "")
                        onClicked: root.runCtl("repeat", [])
                        PlasmaComponents3.ToolTip { text: "Repeat Mode: " + root.repeatMode }
                    }
                }

                // Persistent Volume & Mute Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    PlasmaComponents3.ToolButton {
                        icon.name: root.isMuted
                            ? "audio-volume-muted"
                            : (root.volumeDb < -12 ? "audio-volume-low" : (root.volumeDb < -3 ? "audio-volume-medium" : "audio-volume-high"))
                        checked: root.isMuted
                        checkable: true
                        onClicked: root.toggleMute()
                        PlasmaComponents3.ToolTip {
                            text: root.isMuted
                                ? ("Unmute (Restore to " + (root.preMuteVolumeDb >= 0 ? "+" : "") + root.preMuteVolumeDb.toFixed(1) + " dB)")
                                : "Mute Audio"
                        }
                    }

                    PlasmaComponents3.Slider {
                        id: volSlider
                        Layout.fillWidth: true
                        from: -30
                        to: 6
                        stepSize: 0.5
                        value: pressed ? value : root.volumeDb
                        onMoved: root.setVolume(value)
                    }

                    PlasmaComponents3.Label {
                        Layout.preferredWidth: 58
                        horizontalAlignment: Text.AlignRight
                        text: root.isMuted
                            ? "Muted"
                            : ((root.volumeDb >= 0 ? "+" : "") + root.volumeDb.toFixed(1) + " dB")
                        font.bold: root.isMuted
                        color: root.isMuted ? "#f38ba8" : Kirigami.Theme.textColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
            }
        }

        // ============================================================
        // MAIN NAVIGATION TABS (Queue | Sources | Equalizer | Audio)
        // ============================================================
        PlasmaComponents3.TabBar {
            id: mainTabs
            Layout.fillWidth: true

            PlasmaComponents3.TabButton {
                text: "Queue"
                icon.name: "view-media-playlist"
            }
            PlasmaComponents3.TabButton {
                text: "Sources"
                icon.name: "folder-music"
            }
            PlasmaComponents3.TabButton {
                text: "Equalizer"
                icon.name: "view-media-equalizer"
            }
            PlasmaComponents3.TabButton {
                text: "Audio"
                icon.name: "audio-card"
            }
        }

        // ============================================================
        // TAB CONTENT STACK
        // ============================================================
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabs.currentIndex

            // --------------------------------------------------------
            // TAB 0: ACTIVE QUEUE
            // --------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    visible: root.queueTracks.length > 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: root.activePlaylist !== "" ? ("Active: " + root.activePlaylist) : "Current Queue"
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.85
                        elide: Text.ElideRight
                    }

                    PlasmaComponents3.Label {
                        text: root.queueTracks.length + " tracks"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        opacity: 0.65
                    }
                }

                PlasmaComponents3.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: queueListView
                        clip: true
                        model: root.queueTracks
                        spacing: 2

                        delegate: PlasmaComponents3.ItemDelegate {
                            width: queueListView.width
                            highlighted: modelData.index === root.trackIndex

                            contentItem: RowLayout {
                                spacing: 8

                                Kirigami.Icon {
                                    source: modelData.index === root.trackIndex
                                        ? (root.playbackState === "playing" ? "media-playback-start" : "media-playback-pause")
                                        : "audio-x-generic"
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    PlasmaComponents3.Label {
                                        Layout.fillWidth: true
                                        text: (modelData.index + 1) + ". " + (modelData.title || "Unknown Track")
                                        font.bold: modelData.index === root.trackIndex
                                        elide: Text.ElideRight
                                    }

                                    PlasmaComponents3.Label {
                                        visible: (modelData.artist || "") !== ""
                                        Layout.fillWidth: true
                                        text: modelData.artist || ""
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        opacity: 0.7
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            onClicked: root.runCtl("play-index", [String(modelData.index)])
                        }

                        Kirigami.PlaceholderMessage {
                            anchors.centerIn: parent
                            width: parent.width - 32
                            visible: root.queueTracks.length === 0
                            icon.name: "view-media-playlist"
                            text: root.isRunning ? "Queue is Empty" : "Player is Offline"
                            explanation: "Open the 'Sources' tab to start a playlist, radio stream, or cloud provider."
                        }
                    }
                }
            }

            // --------------------------------------------------------
            // TAB 1: SOURCES (Clean 3-Category Browser + Station Drilldown)
            // --------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: root.browsedProviderKey === ""

                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        icon.name: "folder-music"
                        text: "Playlists"
                        checked: fullRoot.sourceCategoryIndex === 0
                        checkable: true
                        onClicked: fullRoot.sourceCategoryIndex = 0
                    }

                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        icon.name: "radio"
                        text: "Radio & URL"
                        checked: fullRoot.sourceCategoryIndex === 1
                        checkable: true
                        onClicked: fullRoot.sourceCategoryIndex = 1
                    }

                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        icon.name: "cloud"
                        text: "Cloud"
                        checked: fullRoot.sourceCategoryIndex === 2
                        checkable: true
                        onClicked: fullRoot.sourceCategoryIndex = 2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    visible: root.browsedProviderKey !== ""

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        PlasmaComponents3.Button {
                            icon.name: "go-previous"
                            text: "Back"
                            onClicked: root.closeProviderBrowser()
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: root.browsedProviderName + " — Stations & Playlists"
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.Button {
                            icon.name: "media-playback-start"
                            text: "Play Default"
                            onClicked: {
                                root.runCtl("load-provider", [root.browsedProviderKey]);
                                root.closeProviderBrowser();
                                mainTabs.currentIndex = 0;
                            }
                        }
                    }

                    PlasmaComponents3.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: browsedListView
                            clip: true
                            model: root.browsedProviderPlaylists
                            spacing: 3

                            delegate: PlasmaComponents3.ItemDelegate {
                                width: browsedListView.width

                                contentItem: RowLayout {
                                    spacing: 8

                                    Kirigami.Icon {
                                        source: "media-playlist-play"
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                    }

                                    PlasmaComponents3.Label {
                                        Layout.fillWidth: true
                                        text: modelData.name || modelData.id || "Station"
                                        elide: Text.ElideRight
                                    }

                                    PlasmaComponents3.Button {
                                        icon.name: "media-playback-start"
                                        text: "Play"
                                        onClicked: {
                                            var plId = modelData.id || modelData.name;
                                            root.runCtl("load-provider", [root.browsedProviderKey, plId]);
                                            root.closeProviderBrowser();
                                            mainTabs.currentIndex = 0;
                                        }
                                    }
                                }

                                onClicked: {
                                    var plId = modelData.id || modelData.name;
                                    root.runCtl("load-provider", [root.browsedProviderKey, plId]);
                                    root.closeProviderBrowser();
                                    mainTabs.currentIndex = 0;
                                }
                            }

                            Kirigami.PlaceholderMessage {
                                anchors.centerIn: parent
                                width: parent.width - 32
                                visible: root.browsedProviderPlaylists.length === 0
                                icon.name: root.loadingProviderPlaylists ? "view-refresh" : "radio"
                                text: root.loadingProviderPlaylists ? "Loading stations & playlists…" : "No sub-playlists returned"
                                explanation: root.loadingProviderPlaylists ? "" : "Click 'Play Default' above to start this source directly."
                            }
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.browsedProviderKey === ""
                    currentIndex: fullRoot.sourceCategoryIndex

                    // SUB-TAB 0: LOCAL PLAYLISTS
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: "Saved Local Playlists"
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.85
                            }

                            PlasmaComponents3.ToolButton {
                                icon.name: "view-refresh"
                                text: "Refresh"
                                onClicked: root.refreshDetails()
                            }
                        }

                        PlasmaComponents3.ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: localPlaylistView
                                clip: true
                                model: root.localPlaylists
                                spacing: 4

                                delegate: Rectangle {
                                    width: localPlaylistView.width
                                    height: 44
                                    radius: 6
                                    color: (root.activePlaylist === modelData.name || root.activePlaylist === ("local:" + modelData.name))
                                        ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    border.width: 1
                                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Kirigami.Icon {
                                            source: modelData.name === "Favorites" ? "favorite" : "view-media-playlist"
                                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            PlasmaComponents3.Label {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            PlasmaComponents3.Label {
                                                text: (modelData.track_count !== undefined ? modelData.track_count : 0) + " tracks"
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                opacity: 0.7
                                            }
                                        }

                                        PlasmaComponents3.Button {
                                            icon.name: "media-playback-start"
                                            text: "Play"
                                            onClicked: {
                                                root.runCtl("load-playlist", [modelData.name]);
                                                mainTabs.currentIndex = 0;
                                            }
                                        }
                                    }
                                }

                                Kirigami.PlaceholderMessage {
                                    anchors.centerIn: parent
                                    width: parent.width - 32
                                    visible: root.localPlaylists.length === 0
                                    icon.name: "folder-music"
                                    text: "No Local Playlists Found"
                                    explanation: "Create playlists via 'cliamp playlist create <Name> <Folder>'."
                                }
                            }
                        }
                    }

                    // SUB-TAB 1: RADIO, PODCASTS & CUSTOM STREAM URL
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        PlasmaComponents3.ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: [
                                        { key: "cliamp", name: "cliamp Radio", desc: "Curated synthwave, lofi, EDM & NCS stations", icon: "radio" },
                                        { key: "radio", name: "Internet Radio", desc: "Global online radio station browser", icon: "network-wireless" },
                                        { key: "podcast", name: "Podcasts", desc: "Podcast episodes & feeds", icon: "podcast" }
                                    ]

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 50
                                        radius: 6
                                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                        border.width: 1
                                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Kirigami.Icon {
                                                source: modelData.icon
                                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0

                                                PlasmaComponents3.Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.name
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }

                                                PlasmaComponents3.Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.desc
                                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                    opacity: 0.7
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            PlasmaComponents3.Button {
                                                icon.name: "view-list-details"
                                                text: "Browse"
                                                onClicked: root.browseProvider(modelData.key, modelData.name)
                                                PlasmaComponents3.ToolTip { text: "Browse stations / channels" }
                                            }

                                            PlasmaComponents3.Button {
                                                icon.name: "media-playback-start"
                                                text: "Play"
                                                highlighted: true
                                                onClicked: {
                                                    root.runCtl("load-provider", [modelData.key]);
                                                    mainTabs.currentIndex = 0;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: urlCol.implicitHeight + 14
                            radius: 6
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                            ColumnLayout {
                                id: urlCol
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 4

                                PlasmaComponents3.Label {
                                    text: "Play Direct Stream or YouTube URL"
                                    font.bold: true
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    opacity: 0.85
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    PlasmaComponents3.TextField {
                                        id: urlInput
                                        Layout.fillWidth: true
                                        placeholderText: "https://… (Radio stream, YouTube, SoundCloud, MP3)"
                                        onAccepted: {
                                            if (text.trim() !== "") {
                                                root.runCtl("load-url", [text.trim()]);
                                                text = "";
                                                mainTabs.currentIndex = 0;
                                            }
                                        }
                                    }

                                    PlasmaComponents3.Button {
                                        icon.name: "media-playback-start"
                                        text: "Play URL"
                                        enabled: urlInput.text.trim() !== ""
                                        onClicked: {
                                            root.runCtl("load-url", [urlInput.text.trim()]);
                                            urlInput.text = "";
                                            mainTabs.currentIndex = 0;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SUB-TAB 2: CLOUD SERVICES
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: "Cloud & Media Server Integrations"
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                opacity: 0.85
                            }

                            PlasmaComponents3.Button {
                                icon.name: "configure"
                                text: "Setup Wizard"
                                onClicked: root.runCtl("open-setup", [Plasmoid.configuration.preferredTerminal || "auto"])
                                PlasmaComponents3.ToolTip {
                                    text: "Open 'cliamp setup' in Terminal to connect Spotify, YouTube Music, Tidal, Navidrome, etc."
                                }
                            }
                        }

                        PlasmaComponents3.ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: cloudProviderView
                                clip: true
                                spacing: 4
                                model: [
                                    { key: "spotify", name: "Spotify", desc: "Spotify Connect & playlists", icon: "media-optical-audio" },
                                    { key: "ytmusic", name: "YouTube Music", desc: "YouTube Music library & mixes", icon: "video-television" },
                                    { key: "soundcloud", name: "SoundCloud", desc: "Tracks, sets & likes", icon: "cloud" },
                                    { key: "bandcamp", name: "Bandcamp", desc: "Bandcamp collection & streams", icon: "album" },
                                    { key: "tidal", name: "Tidal", desc: "Tidal lossless streaming", icon: "audio-x-flac" },
                                    { key: "qobuz", name: "Qobuz", desc: "Qobuz hi-res audio", icon: "audio-x-generic" },
                                    { key: "navidrome", name: "Navidrome / Subsonic", desc: "Self-hosted music server", icon: "network-server" },
                                    { key: "jellyfin", name: "Jellyfin", desc: "Jellyfin media library", icon: "multimedia-player" },
                                    { key: "plex", name: "Plex", desc: "Plex music library", icon: "multimedia-player" }
                                ]

                                delegate: Rectangle {
                                    width: cloudProviderView.width
                                    height: 46
                                    radius: 6
                                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                    border.width: 1
                                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Kirigami.Icon {
                                            source: modelData.icon
                                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            PlasmaComponents3.Label {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            PlasmaComponents3.Label {
                                                Layout.fillWidth: true
                                                text: modelData.desc
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                                opacity: 0.7
                                                elide: Text.ElideRight
                                            }
                                        }

                                        PlasmaComponents3.Button {
                                            icon.name: "view-list-details"
                                            text: "Browse"
                                            onClicked: root.browseProvider(modelData.key, modelData.name)
                                        }

                                        PlasmaComponents3.Button {
                                            icon.name: "media-playback-start"
                                            text: "Start"
                                            onClicked: {
                                                root.runCtl("load-provider", [modelData.key]);
                                                mainTabs.currentIndex = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --------------------------------------------------------
            // TAB 2: 10-BAND GRAPHIC EQUALIZER & PRESETS
            // --------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    PlasmaComponents3.Label {
                        text: "Preset:"
                        font.bold: true
                    }

                    PlasmaComponents3.ComboBox {
                        Layout.fillWidth: true
                        model: root.eqPresetsList
                        enabled: root.isRunning
                        currentIndex: Math.max(0, root.eqPresetsList.indexOf(root.eqPreset))
                        onActivated: function(index) {
                            var chosen = root.eqPresetsList[index];
                            if (chosen) {
                                root.runCtl("eq", [chosen]);
                            }
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "edit-clear"
                        text: "Reset Flat"
                        enabled: root.isRunning
                        onClicked: root.runCtl("eq", ["Flat"])
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Repeater {
                            model: 10

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                readonly property double bandVal: (root.eqBands && root.eqBands.length > index) ? Number(root.eqBands[index]) : 0

                                PlasmaComponents3.Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: (bandVal > 0 ? "+" : "") + Math.round(bandVal)
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.85
                                    opacity: 0.8
                                }

                                PlasmaComponents3.Slider {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillHeight: true
                                    orientation: Qt.Vertical
                                    from: -12
                                    to: 12
                                    stepSize: 1
                                    value: pressed ? value : parent.bandVal
                                    enabled: root.isRunning
                                    onMoved: root.runCtl("eq-band", [String(index), String(Math.round(value))])
                                }

                                PlasmaComponents3.Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: fullRoot.eqFreqLabels[index]
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize * 0.85
                                    opacity: 0.75
                                }
                            }
                        }
                    }
                }
            }

            // --------------------------------------------------------
            // TAB 3: AUDIO CONTROLS (Output Mode, Playback Speed, Seek)
            // --------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: audioCardCol.implicitHeight + 16
                    radius: 8
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                    ColumnLayout {
                        id: audioCardCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: "Audio Output Mode"
                                font.bold: true
                            }

                            PlasmaComponents3.Button {
                                text: root.isMono ? "Mono (Active)" : "Stereo"
                                checkable: true
                                checked: root.isMono
                                enabled: root.isRunning
                                onClicked: root.runCtl("mono", [])
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            PlasmaComponents3.Label {
                                text: "Playback Speed:"
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Repeater {
                                model: [0.75, 1.0, 1.25, 1.5, 2.0]

                                delegate: PlasmaComponents3.Button {
                                    text: modelData + "x"
                                    checkable: true
                                    checked: Math.abs(root.playbackSpeed - modelData) < 0.05
                                    enabled: root.isRunning
                                    onClicked: root.runCtl("speed", [String(modelData)])
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            PlasmaComponents3.Label {
                                text: "Quick Seek:"
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            PlasmaComponents3.Button {
                                text: "-30s"
                                enabled: root.isRunning && root.isSeekable
                                onClicked: root.runCtl("seek", ["-30"])
                            }
                            PlasmaComponents3.Button {
                                text: "-10s"
                                enabled: root.isRunning && root.isSeekable
                                onClicked: root.runCtl("seek", ["-10"])
                            }
                            PlasmaComponents3.Button {
                                text: "+10s"
                                enabled: root.isRunning && root.isSeekable
                                onClicked: root.runCtl("seek", ["10"])
                            }
                            PlasmaComponents3.Button {
                                text: "+30s"
                                enabled: root.isRunning && root.isSeekable
                                onClicked: root.runCtl("seek", ["30"])
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
