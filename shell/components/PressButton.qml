import QtQuick
import qs.core

// Rounded button with hover tint and a springy squash on press.
// Put content inside; it is centered unless anchored otherwise.
Item {
    id: root

    default property alias content: inner.data
    property alias radius: bg.radius
    property color color: "transparent"
    property color hoverColor: Theme.islandRaisedHover
    property color activeColor: Theme.primary
    property bool active: false          // toggled-on look
    property bool highlighted: false     // keyboard selection
    property bool enabled: true
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed

    signal clicked
    signal rightClicked
    signal middleClicked

    implicitWidth: 36
    implicitHeight: 36
    opacity: enabled ? 1 : 0.4
    scale: pressed ? 0.94 : 1

    Behavior on scale {
        Spring { preset: "bouncy" }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: root.active ? root.activeColor : (root.hovered || root.highlighted) ? root.hoverColor : root.color
        Behavior on color {
            ColorAnimation { duration: Motion.fast }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.rightClicked();
            else if (event.button === Qt.MiddleButton)
                root.middleClicked();
            else
                root.clicked();
        }
    }
}
