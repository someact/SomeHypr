import QtQuick
import qs.core
import qs.components
import qs.services

// Screen recording: pulsing red dot, elapsed time and a stop button.
// Clicking anywhere on the island stops the recording (see Island.qml).
Item {
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 9
            height: 9
            radius: 4.5
            color: "#ff453a"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: !GameMode.active
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            mono: true
            text: Recorder.elapsedText
            font.weight: Theme.font.weightTitle
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Recorder.sound
            name: "volume_up"
            size: 16
            color: Theme.fgIslandDim
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 11
            color: Theme.islandRaised
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 2
                color: Theme.fgIsland
            }
        }
    }
}
