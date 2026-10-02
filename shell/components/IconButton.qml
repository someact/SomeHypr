import QtQuick
import qs.core

PressButton {
    id: root
    property string icon
    property real iconSize: 20
    property color iconColor: active ? Theme.fgPrimary : Theme.fgIsland

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        fill: root.active ? 1 : 0
        color: root.iconColor
    }
}
