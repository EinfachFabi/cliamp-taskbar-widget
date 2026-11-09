import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: compactRoot
    clip: true

    readonly property bool isHorizontal: plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property string panelDisplayText: {
        if (!root.isRunning) return "cliamp";
        if (root.trackTitle !== "") return root.trackArtist !== "" ? (root.trackArtist + " – " + root.trackTitle) : root.trackTitle;
        if (root.activePlaylist !== "") return root.activePlaylist;
        return root.playbackState === "playing" ? "Playing…" : "cliamp";
    }

    readonly property bool showVis: isHorizontal
    readonly property bool showTrack: isHorizontal && (plasmoid.configuration.showTrackInPanel !== false) && panelDisplayText !== ""

    Layout.minimumWidth: isHorizontal ? (Math.min(height, 26) + (showVis ? 28 : 0) + (showTrack ? 120 : 0) + 12) : height
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth

    MouseArea {
        id: compactMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        property bool wasExpanded: false

        onPressed: {
            if (mouse.button === Qt.LeftButton) {
                wasExpanded = plasmoid.expanded;
            }
        }

        onClicked: {
            if (mouse.button === Qt.MiddleButton) {
                root.runCtl("toggle", []);
            } else if (mouse.button === Qt.LeftButton) {
                plasmoid.expanded = !wasExpanded;
            }
        }

        onWheel: {
            var step = plasmoid.configuration.volumeStepDb || 1.5;
            if (wheel.angleDelta.y > 0) root.stepVolume(step);
            else if (wheel.angleDelta.y < 0) root.stepVolume(-step);
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        spacing: 5

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
                color: !root.isRunning ? "#6c7086" : (root.isMuted ? "#f38ba8" : (root.playbackState === "playing" ? "#a6e3a1" : "#89b4fa"))
            }
        }

        Rectangle {
            visible: compactRoot.showVis
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 23
            Layout.preferredHeight: Math.min(18, Math.max(12, compactRoot.height - 6))
            radius: 3
            color: "#181825"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            Row {
                anchors.centerIn: parent
                spacing: 2
                height: parent.height - 4

                Repeater {
                    model: 5
                    delegate: Item {
                        width: 2.5
                        height: parent.height
                        readonly property double lvl: (root.isRunning && root.playbackState === "playing" && root.visBands.length > index * 2)
                            ? Number(root.visBands[index * 2])
                            : (0.25 + (index % 3) * 0.12)
                        Rectangle {
                            width: 2.5
                            height: Math.max(2, Math.round(parent.height * parent.lvl))
                            anchors.bottom: parent.bottom
                            radius: 1
                            color: index % 2 === 0 ? "#a6e3a1" : "#89b4fa"
                        }
                    }
                }
            }
        }

        PlasmaComponents3.Label {
            visible: compactRoot.showTrack
            Layout.fillWidth: true
            text: compactRoot.panelDisplayText
            elide: Text.ElideRight
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            verticalAlignment: Text.AlignVCenter
        }
    }
}
