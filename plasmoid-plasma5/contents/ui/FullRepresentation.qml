import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28
    Layout.preferredWidth: Kirigami.Units.gridUnit * 25
    Layout.preferredHeight: Kirigami.Units.gridUnit * 31

    readonly property var eqFreqLabels: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    property int sourceCategoryIndex: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
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
                }

                PlasmaComponents3.Label {
                    text: !root.isRunning ? "Offline" : (root.playbackState + " • " + root.runMode)
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    opacity: 0.8
                }
            }

            PlasmaComponents3.Button {
                icon.name: root.isRunning ? "process-stop" : "system-run"
                text: root.isRunning ? "Stop Daemon" : "Start Daemon"
                onClicked: root.runCtl("toggle-daemon", [])
            }

            PlasmaComponents3.ToolButton {
                icon.name: "utilities-terminal"
                onClicked: root.runCtl("open-terminal", [plasmoid.configuration.preferredTerminal || "auto"])
            }

            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                onClicked: root.refreshDetails()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: nowPlayingCol.implicitHeight + 16
            radius: 8
            color: Qt.rgba(0.5, 0.5, 0.5, 0.1)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            ColumnLayout {
                id: nowPlayingCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: !root.isRunning ? "Player Offline" : (root.trackTitle !== "" ? root.trackTitle : "No Track Loaded")
                    font.bold: true
                    elide: Text.ElideRight
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: root.trackArtist !== "" ? (root.trackArtist + (root.activePlaylist !== "" ? " • " + root.activePlaylist : "")) : root.activePlaylist
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    opacity: 0.75
                    elide: Text.ElideRight
                }

                // Live Visualizer Box in Popup Menu (Predefined Default Theme)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 6
                    color: "#181825"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)

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
                                readonly property int bIdx: Math.floor(index / 2)
                                readonly property double lvl: (root.isRunning && root.playbackState === "playing" && root.visBands.length > bIdx)
                                    ? Number(root.visBands[bIdx])
                                    : (0.2 + 0.14 * (Math.sin(index * 0.5) * 0.5 + 0.5))
                                Rectangle {
                                    width: parent.width
                                    height: Math.max(3, Math.round(parent.height * parent.lvl))
                                    anchors.bottom: parent.bottom
                                    radius: 1.5
                                    color: parent.lvl > 0.75 ? "#f38ba8" : (parent.lvl > 0.48 ? "#f9e2af" : (index % 3 === 0 ? "#89b4fa" : "#a6e3a1"))
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-playlist-shuffle"
                        checked: root.isShuffle
                        checkable: true
                        enabled: root.isRunning
                        onClicked: root.runCtl("shuffle", [])
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-skip-backward"
                        onClicked: root.runCtl("prev", [])
                    }

                    PlasmaComponents3.Button {
                        icon.name: root.playbackState === "playing" ? "media-playback-pause" : "media-playback-start"
                        text: root.playbackState === "playing" ? "Pause" : "Play"
                        onClicked: root.runCtl("toggle", [])
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-playback-stop"
                        enabled: root.isRunning
                        onClicked: root.runCtl("stop", [])
                    }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-skip-forward"
                        onClicked: root.runCtl("next", [])
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents3.ToolButton {
                        icon.name: "media-playlist-repeat"
                        checked: root.repeatMode !== "Off"
                        checkable: true
                        enabled: root.isRunning
                        onClicked: root.runCtl("repeat", [])
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    PlasmaComponents3.ToolButton {
                        icon.name: root.isMuted ? "audio-volume-muted" : "audio-volume-high"
                        checked: root.isMuted
                        checkable: true
                        onClicked: root.toggleMute()
                    }

                    PlasmaComponents3.Slider {
                        Layout.fillWidth: true
                        from: -30
                        to: 6
                        stepSize: 0.5
                        value: pressed ? value : root.volumeDb
                        onMoved: root.setVolume(value)
                    }

                    PlasmaComponents3.Label {
                        text: root.isMuted ? "Muted" : ((root.volumeDb >= 0 ? "+" : "") + root.volumeDb.toFixed(1) + " dB")
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }
            }
        }

        PlasmaComponents3.TabBar {
            id: mainTabs
            Layout.fillWidth: true

            PlasmaComponents3.TabButton { text: "Queue" }
            PlasmaComponents3.TabButton { text: "Sources" }
            PlasmaComponents3.TabButton { text: "Equalizer" }
            PlasmaComponents3.TabButton { text: "Audio" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabs.currentIndex

            PlasmaComponents3.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: queueListView
                    clip: true
                    model: root.queueTracks
                    delegate: PlasmaComponents3.ItemDelegate {
                        width: queueListView.width
                        highlighted: modelData.index === root.trackIndex
                        text: (modelData.index + 1) + ". " + (modelData.artist ? modelData.artist + " - " : "") + (modelData.title || "")
                        onClicked: root.runCtl("play-index", [String(modelData.index)])
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        text: "Playlists"
                        checked: fullRoot.sourceCategoryIndex === 0
                        checkable: true
                        onClicked: fullRoot.sourceCategoryIndex = 0
                    }
                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        text: "Radio & URL"
                        checked: fullRoot.sourceCategoryIndex === 1
                        checkable: true
                        onClicked: fullRoot.sourceCategoryIndex = 1
                    }
                    PlasmaComponents3.Button {
                        Layout.fillWidth: true
                        text: "Cloud"
                        checked: fullRoot.sourceCategoryIndex === 2
                        checkable: true
                        onClicked: fullRoot.sourceCategoryIndex = 2
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: fullRoot.sourceCategoryIndex

                    PlasmaComponents3.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ListView {
                            id: plView
                            clip: true
                            model: root.localPlaylists
                            delegate: PlasmaComponents3.ItemDelegate {
                                width: plView.width
                                text: modelData.name + " (" + (modelData.track_count || 0) + " tracks)"
                                onClicked: {
                                    root.runCtl("load-playlist", [modelData.name]);
                                    mainTabs.currentIndex = 0;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        Repeater {
                            model: [
                                { key: "cliamp", name: "cliamp Radio" },
                                { key: "radio", name: "Internet Radio" },
                                { key: "podcast", name: "Podcasts" }
                            ]
                            delegate: PlasmaComponents3.Button {
                                Layout.fillWidth: true
                                text: "Play " + modelData.name
                                onClicked: {
                                    root.runCtl("load-provider", [modelData.key]);
                                    mainTabs.currentIndex = 0;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            PlasmaComponents3.TextField {
                                id: urlField5
                                Layout.fillWidth: true
                                placeholderText: "https://… stream or YouTube URL"
                            }
                            PlasmaComponents3.Button {
                                text: "Play URL"
                                onClicked: {
                                    if (urlField5.text.trim() !== "") {
                                        root.runCtl("load-url", [urlField5.text.trim()]);
                                        urlField5.text = "";
                                        mainTabs.currentIndex = 0;
                                    }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    PlasmaComponents3.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ListView {
                            id: cloudView5
                            clip: true
                            model: ["spotify", "ytmusic", "soundcloud", "bandcamp", "tidal", "qobuz", "navidrome", "jellyfin", "plex"]
                            delegate: PlasmaComponents3.ItemDelegate {
                                width: cloudView5.width
                                text: "Start " + modelData
                                onClicked: {
                                    root.runCtl("load-provider", [modelData]);
                                    mainTabs.currentIndex = 0;
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                PlasmaComponents3.ComboBox {
                    Layout.fillWidth: true
                    model: root.eqPresetsList
                    enabled: root.isRunning
                    currentIndex: Math.max(0, root.eqPresetsList.indexOf(root.eqPreset))
                    onActivated: root.runCtl("eq", [root.eqPresetsList[index]])
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2
                    Repeater {
                        model: 10
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            readonly property double bandVal: (root.eqBands && root.eqBands.length > index) ? Number(root.eqBands[index]) : 0
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
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents3.Label { Layout.fillWidth: true; text: "Audio Output Mode"; font.bold: true }
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
                    PlasmaComponents3.Label { text: "Speed:"; font.bold: true }
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

                Item { Layout.fillHeight: true }
            }
        }
    }
}
