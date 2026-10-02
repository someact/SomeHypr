import QtQuick
import qs.core

// Phone-style quick toggle tile: icon, title and optional subtitle.
PressButton {
    id: root

    property string icon
    property string title
    property string subtitle

    implicitWidth: 170
    implicitHeight: 52
    radius: Theme.radius.large
    color: Theme.islandRaised
    activeColor: Theme.primary

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 22
            fill: root.active ? 1 : 0
            color: root.active ? Theme.fgPrimary : Theme.fgIsland
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 42
            Label {
                width: parent.width
                text: root.title
                font.weight: Font.DemiBold
                color: root.active ? Theme.fgPrimary : Theme.fgIsland
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                font.pixelSize: Theme.font.small
                color: root.active ? Theme.fgPrimary : Theme.fgIslandDim
                opacity: 0.85
            }
        }
    }
}
