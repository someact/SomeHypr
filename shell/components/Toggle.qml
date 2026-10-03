import QtQuick
import qs.core

// Phone-style quick toggle tile: icon, title and optional subtitle, or the
// icon alone (`compact`).
PressButton {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool compact: false

    implicitWidth: 170
    implicitHeight: 52
    // Off: a pill. On: a squircle (Material 3 Expressive tiles)
    radius: height / 2
    activeRadius: Theme.radius.normal
    color: Theme.islandRaised
    activeColor: Theme.primary

    Icon {
        visible: root.compact
        anchors.centerIn: parent
        name: root.icon
        size: 22
        fill: root.active ? 1 : 0
        color: root.active ? Theme.fgPrimary : Theme.fgIsland
    }

    Row {
        visible: !root.compact
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
                font.weight: Theme.font.weightTitle
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
