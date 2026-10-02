import QtQuick
import qs.core

// Screen-center crosshair (Config.overlay.crosshair). Plain rectangles, so it
// costs nothing to draw and never takes input.
Item {
    id: root

    readonly property var c: Config.overlay.crosshair
    readonly property real len: c.size
    readonly property real th: c.thickness
    readonly property real gap: c.gap
    readonly property real ow: c.outline ? 1 : 0

    width: (len + gap) * 2 + th
    height: width

    component Bar: Rectangle {
        color: root.c.color
        antialiasing: false
        border.width: root.ow
        border.color: Qt.rgba(0, 0, 0, 0.8)
    }

    Repeater {
        model: root.len > 0 ? 4 : 0
        Bar {
            required property int index
            readonly property bool horizontal: index < 2
            width: horizontal ? root.len : root.th
            height: horizontal ? root.th : root.len
            x: horizontal ? (index === 0 ? 0 : root.width - root.len) : (root.width - root.th) / 2
            y: horizontal ? (root.height - root.th) / 2 : (index === 2 ? 0 : root.height - root.len)
        }
    }
    Bar {
        visible: root.c.dot
        width: root.th + 2
        height: width
        anchors.centerIn: parent
    }
}
