import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// A live window preview placed where the window sits on its workspace tile.
// Click focuses it, middle-click closes it, drag drops it on another workspace.
Item {
    id: thumb

    required property HyprlandToplevel modelData
    required property var layout   // the overview grid: tile geometry, drag and drop

    readonly property var ipc: modelData.lastIpcObject
    readonly property point origin: layout.originFor(modelData)
    readonly property real factor: layout.factorFor(modelData)
    readonly property HyprlandMonitor monitor: modelData.monitor
    readonly property bool dragging: layout.dragged === thumb
    readonly property bool hovered: mouse.containsMouse && layout.dragged === null

    readonly property real homeX: origin.x + Math.max(0, ((ipc?.at?.[0] ?? 0) - (monitor?.x ?? 0)) * factor)
    readonly property real homeY: origin.y + Math.max(0, ((ipc?.at?.[1] ?? 0) - (monitor?.y ?? 0)) * factor)

    property real dragX: 0
    property real dragY: 0

    visible: ipc?.at !== undefined
    x: dragging ? dragX : homeX
    y: dragging ? dragY : homeY
    width: Math.max(12, (ipc?.size?.[0] ?? 0) * factor)
    height: Math.max(12, (ipc?.size?.[1] ?? 0) * factor)
    z: dragging ? 100 : ipc?.floating ? 2 : 1
    scale: dragging ? 1.04 : mouse.pressed ? 0.97 : 1

    Behavior on x {
        enabled: !thumb.dragging
        Spring { preset: "snappy" }
    }
    Behavior on y {
        enabled: !thumb.dragging
        Spring { preset: "snappy" }
    }
    Behavior on width {
        Spring { preset: "snappy" }
    }
    Behavior on height {
        Spring { preset: "snappy" }
    }
    Behavior on scale {
        Spring { preset: "bouncy" }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radius.small
        color: Theme.surfaceHigh

        ScreencopyView {
            anchors.fill: parent
            captureSource: thumb.modelData.wayland
            live: true
        }
    }

    // Focus ring, hover tint
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.small
        color: thumb.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        border.width: thumb.modelData.activated ? 2 : 1
        border.color: thumb.modelData.activated ? Theme.primary : Qt.rgba(1, 1, 1, thumb.hovered ? 0.3 : 0.1)
    }

    IconImage {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.min(8, parent.height * 0.08)
        implicitSize: Math.min(30, thumb.width * 0.3, thumb.height * 0.4)
        source: HyprData.appIcon(thumb.modelData.wayland?.appId ?? thumb.ipc?.class ?? "")
    }

    MouseArea {
        id: mouse

        property point pressAt
        property bool moved: false

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: thumb.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onPressed: event => {
            pressAt = Qt.point(event.x, event.y);
            moved = false;
        }
        onPositionChanged: event => {
            if (!pressed || !(pressedButtons & Qt.LeftButton))
                return;
            const dx = event.x - pressAt.x, dy = event.y - pressAt.y;
            if (!moved && Math.hypot(dx, dy) < 6)
                return;
            if (!moved) {
                moved = true;
                thumb.dragX = thumb.x;
                thumb.dragY = thumb.y;
                thumb.layout.dragged = thumb;
            }
            thumb.dragX += dx;
            thumb.dragY += dy;
            thumb.layout.dragOver(thumb.dragX + thumb.width / 2, thumb.dragY + thumb.height / 2);
        }
        onReleased: event => {
            if (moved) {
                thumb.layout.drop(thumb);
                return;
            }
            if (event.button === Qt.MiddleButton)
                HyprData.closeWindow(thumb.modelData);
            else
                thumb.layout.focusWindow(thumb.modelData);
        }
        onCanceled: if (moved) thumb.layout.drop(null)
    }
}
