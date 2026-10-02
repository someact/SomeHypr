import QtQuick
import Quickshell.Widgets
import qs.core
import qs.components

// One setting: icon, title, subtitle on the left; a control on the right.
// `changed` shows a reset button that calls reset().
Item {
    id: row

    property string icon
    property string iconSource          // an image (app icon) instead of a symbol
    property string title
    property string subtitle
    property bool changed: false
    property bool enabled: true
    default property alias control: slot.data
    signal reset

    width: parent?.width ?? 600
    implicitHeight: Math.max(56, text.implicitHeight + 20, slot.childrenRect.height + 16)
    opacity: enabled ? 1 : 0.45

    IconImage {
        visible: row.iconSource !== ""
        x: 13
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 24
        source: row.iconSource
    }
    Icon {
        id: iconItem
        visible: row.icon !== "" && row.iconSource === ""
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        name: row.icon
        size: 22
        color: Theme.fgSurfaceVariant
    }
    Column {
        id: text
        anchors.verticalCenter: parent.verticalCenter
        x: row.icon !== "" || row.iconSource !== "" ? 50 : 16
        width: slot.x - x - 12
        SText {
            width: parent.width
            text: row.title
        }
        SText {
            visible: text !== ""
            width: parent.width
            text: row.subtitle
            dim: true
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
    }
    IconButton {
        visible: row.changed
        anchors.right: slot.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        icon: "restart_alt"
        iconSize: 18
        iconColor: Theme.fgSurfaceVariant
        hoverColor: Theme.surfaceHigh
        onClicked: row.reset()
    }
    Item {
        id: slot
        enabled: row.enabled
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
