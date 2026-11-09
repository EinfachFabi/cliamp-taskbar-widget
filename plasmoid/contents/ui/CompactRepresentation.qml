import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot
    clip: true

    function panelBarColor(idx, level) {
        if (level > 0.75) return "#f38ba8";
        if (level > 0.48) return "#f9e2af";
        return idx % 2 === 0 ? "#a6e3a1" : "#89b4fa";
    }

    MouseArea {
        id: compactMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property bool wasExpanded: false

        onPressed: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                wasExpanded = root.expanded;
            }
        }

        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                root.runCtl("toggle", []);
            } else if (mouse.button === Qt.LeftButton) {
                root.expanded = !wasExpanded;
            }
        }

        onWheel: function(wheel) {
            var step = Plasmoid.configuration.volumeStepDb || 1.5;
            if (wheel.angleDelta.y > 0) {
                root.stepVolume(step);
            } else if (wheel.angleDelta.y < 0) {
                root.stepVolume(-step);
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        spacing: 5

        // 1. cliamp Icon + Status Dot
        Item {
            readonly property int iconBoxSize: Math.max(16, Math.min(compactRoot.height - 4, 24))
            Layout.preferredWidth: iconBoxSize
            Layout.preferredHeight: iconBoxSize
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.fill: parent
                source: Qt.resolvedUrl("../images/cliamp.svg")
                active: compactMouse.containsMouse
            }

            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                border.width: 1
                border.color: "#11111b"
                color: {
                    if (!root.isRunning) return "#6c7086";
                    if (root.isMuted) return "#f38ba8";
                    if (root.playbackState === "playing") return "#a6e3a1";
                    if (root.playbackState === "paused") return "#f9e2af";
                    return "#89b4fa";
                }
            }
        }

        // 2. Mini Live Visualizer in Taskbar (Predefined Default Theme)
        Rectangle {
            visible: root.showPanelVis
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 23
            Layout.preferredHeight: Math.min(18, Math.max(12, compactRoot.height - 6))
            radius: 3
            color: "#181825"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
            clip: true

            Row {
                anchors.centerIn: parent
                spacing: 2
                height: parent.height - 4

                Repeater {
                    model: 5

                    delegate: Item {
                        width: 2.5
                        height: parent.height

                        readonly property double rawLevel: (root.visBands && root.visBands.length > index * 2)
                            ? Number(root.visBands[index * 2])
                            : 0.25
                        readonly property double displayLevel: (root.isRunning && root.playbackState === "playing")
                            ? Math.min(1.0, Math.max(0.18, rawLevel))
                            : (0.22 + (index % 3) * 0.12)

                        Rectangle {
                            width: 2.5
                            height: Math.max(2, Math.round(parent.height * parent.displayLevel))
                            anchors.bottom: parent.bottom
                            radius: 1
                            color: compactRoot.panelBarColor(index, parent.displayLevel)
                            opacity: (root.isRunning && root.playbackState === "playing") ? 1.0 : 0.6

                            Behavior on height {
                                NumberAnimation { duration: 80 }
                            }
                        }
                    }
                }
            }
        }

        // 3. Current Track Title & Artist in Taskbar
        PlasmaComponents3.Label {
            visible: root.showPanelTrack
            Layout.fillWidth: true
            text: root.panelDisplayText
            elide: Text.ElideRight
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.bold: root.isRunning && root.playbackState === "playing"
            verticalAlignment: Text.AlignVCenter
        }

        // 4. Optional Inline Transport Controls in Taskbar
        RowLayout {
            visible: root.showPanelButtons
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            PlasmaComponents3.ToolButton {
                implicitWidth: 22
                implicitHeight: 22
                icon.name: "media-skip-backward"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: root.runCtl("prev", [])
                PlasmaComponents3.ToolTip { text: "Previous Track" }
            }

            PlasmaComponents3.ToolButton {
                implicitWidth: 22
                implicitHeight: 22
                icon.name: root.playbackState === "playing" ? "media-playback-pause" : "media-playback-start"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: root.runCtl("toggle", [])
                PlasmaComponents3.ToolTip { text: root.playbackState === "playing" ? "Pause" : "Play" }
            }

            PlasmaComponents3.ToolButton {
                implicitWidth: 22
                implicitHeight: 22
                icon.name: "media-skip-forward"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: root.runCtl("next", [])
                PlasmaComponents3.ToolTip { text: "Next Track" }
            }
        }
    }
}
