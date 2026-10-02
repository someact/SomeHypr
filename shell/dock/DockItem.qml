import QtQuick
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// One app in the dock: icon, running dots, hover lift and a springy press.
// Click focuses (or cycles) the app, middle-click opens a new window, wheel
// cycles its windows, right-click opens the menu. Dragging is handed to the
// dock, which owns the order.
Item {
    id: item

    required property string modelData
    readonly property string key: modelData
    required property var dock   // the dock's content item: order, slots, drag state

    readonly property var windows: Taskbar.windowsOf(key)
    readonly property bool running: windows.length > 0
    readonly property bool focused: windows.some(t => t.activated)
    readonly property bool dragging: dock.dragKey === key
    readonly property bool hovered: mouse.containsMouse && dock.dragKey === ""

    onHoveredChanged: {
        if (hovered)
            dock.hoveredItem = item;
        else if (dock.hoveredItem === item)
            dock.hoveredItem = null;
    }
    Component.onDestruction: if (dock.hoveredItem === item) dock.hoveredItem = null

    property real dragX: 0
    property real dragY: 0

    width: dock.slot
    height: dock.slot
    x: dragging ? dragX : dock.slotX(key)
    y: dragging ? dragY : 0
    z: dragging ? 10 : 0

    Behavior on x {
        enabled: !item.dragging
        Spring { preset: "snappy" }
    }
    Behavior on y {
        enabled: !item.dragging
        Spring { preset: "snappy" }
    }

    IconImage {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 - 3
        implicitSize: Config.dock.iconSize
        source: HyprData.appIcon(item.key)
        transformOrigin: Item.Bottom
        // Dragged out of the dock: about to be unpinned
        opacity: item.dragging && dock.dragOut ? 0.45 : 1
        scale: mouse.pressed && !item.dragging ? 0.88 : item.hovered || item.dragging ? 1.14 : 1
        Behavior on scale {
            Spring { preset: "bouncy" }
        }
        Behavior on opacity {
            NumberAnimation { duration: Motion.fast }
        }
    }

    // Running dots: up to three, the focused app's are wide and colored
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        spacing: 3
        visible: !item.dragging
        Repeater {
            model: Math.min(item.windows.length, 3)
            Rectangle {
                width: item.focused ? 10 : 4
                height: 4
                radius: 2
                color: item.focused ? Theme.primary : Theme.fgSurfaceVariant
                Behavior on width {
                    Spring { preset: "snappy" }
                }
            }
        }
    }

    MouseArea {
        id: mouse

        property point pressAt
        property bool moved: false

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: item.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: event => {
            pressAt = Qt.point(event.x, event.y);
            moved = false;
        }
        onPositionChanged: event => {
            if (!pressed || !(pressedButtons & Qt.LeftButton))
                return;
            const dx = event.x - pressAt.x, dy = event.y - pressAt.y;
            if (!moved && Math.hypot(dx, dy) < 8)
                return;
            if (!moved) {
                moved = true;
                item.dragX = item.x;
                item.dragY = item.y;
                item.dock.startDrag(item.key);
            }
            // event is relative to the item, which itself moves: use deltas
            item.dragX += dx;
            item.dragY += dy;
            item.dock.dragTo(item.dragX + item.width / 2, item.dragY);
        }
        onReleased: event => {
            if (moved) {
                item.dock.endDrag();
                return;
            }
            if (event.button === Qt.RightButton)
                item.dock.openMenu(item);
            else if (event.button === Qt.MiddleButton)
                Taskbar.launch(item.key);
            else
                Taskbar.activate(item.key);
        }
        onCanceled: if (moved) item.dock.endDrag()
        onWheel: event => Taskbar.cycle(item.key, event.angleDelta.y > 0 ? -1 : 1)
    }
}
