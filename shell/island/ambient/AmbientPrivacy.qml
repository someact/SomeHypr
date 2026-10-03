import QtQuick
import qs.core
import qs.components
import qs.services

// Screen share / mic in use: a red dot that is hard to miss.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    property bool live: true    // false under a fullscreen window: the pulse stops

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: "#ff453a"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: !GameMode.active && root.live
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Privacy.screenSharing
            name: "screen_share"
            size: 17
        }
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: Privacy.micActive
            name: "mic"
            size: 17
        }
    }
}
