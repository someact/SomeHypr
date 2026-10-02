import QtQuick
import qs.core
import qs.components

// A game overlay widget: dark glass card with a title bar to drag it by, a pin
// (stay on screen, click-through, while the overlay is closed) and a close
// button. Positions and pins are saved in config.json under `overlay`.
Item {
    id: root

    required property string widgetId
    property string icon
    property string title
    property bool interactive: true       // false while the overlay is closed
    property point defaultPos: Qt.point(80, 120)
    default property alias content: body.data

    readonly property bool pinned: Config.overlay.pinned.includes(widgetId)
    readonly property var saved: Config.overlay.positions?.[widgetId] ?? null

    implicitWidth: 300
    implicitHeight: header.height + body.childrenRect.height + 24
    x: saved?.x ?? defaultPos.x
    y: saved?.y ?? defaultPos.y

    function close() {
        Config.overlay.open = Config.overlay.open.filter(w => w !== widgetId);
        Config.overlay.pinned = Config.overlay.pinned.filter(w => w !== widgetId);
    }
    function togglePin() {
        Config.overlay.pinned = pinned ? Config.overlay.pinned.filter(w => w !== widgetId) : [...Config.overlay.pinned, widgetId];
    }
    function savePos() {
        const p = Object.assign({}, Config.overlay.positions ?? {});
        p[widgetId] = { x: Math.round(x), y: Math.round(y) };
        Config.overlay.positions = p;
    }

    // Pop in
    property real shown: 0
    Component.onCompleted: shown = 1
    opacity: shown * (interactive ? 1 : 0.85)
    scale: 0.94 + shown * 0.06
    Behavior on shown {
        Spring { preset: "snappy" }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.large
        color: Qt.rgba(0, 0, 0, root.interactive ? 0.78 : 0.55)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, root.interactive ? 0.1 : 0.05)
    }

    Item {
        id: header
        width: parent.width
        height: root.interactive ? 40 : 30
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                size: 17
                fill: 1
                color: Theme.primary
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                font.weight: Font.DemiBold
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: root
            drag.threshold: 2
            onReleased: root.savePos()
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: root.interactive
            IconButton {
                width: 28
                height: 28
                iconSize: 16
                icon: "keep"
                active: root.pinned
                onClicked: root.togglePin()
            }
            IconButton {
                width: 28
                height: 28
                iconSize: 16
                icon: "close"
                onClicked: root.close()
            }
        }
    }

    Item {
        id: body
        x: 14
        y: header.height
        width: parent.width - 28
        height: childrenRect.height
        enabled: root.interactive
    }
}
