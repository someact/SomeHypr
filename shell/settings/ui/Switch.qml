import QtQuick
import qs.core
import qs.components

// Material switch; `toggled(on)` fires on click
Item {
    id: sw

    property bool checked: false
    signal toggled(bool on)

    implicitWidth: 52
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? Theme.primary : Theme.surfaceHighest
        border.width: sw.checked ? 0 : 2
        border.color: Theme.outline
        Behavior on color {
            ColorAnimation { duration: Motion.fast }
        }
    }
    Rectangle {
        property real size: sw.checked ? 24 : 16
        width: size
        height: size
        radius: size / 2
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? sw.width - size - 4 : 8
        color: sw.checked ? Theme.fgPrimary : Theme.outline
        Behavior on x {
            Spring { preset: "snappy" }
        }
        Behavior on size {
            Spring { preset: "bouncy" }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
