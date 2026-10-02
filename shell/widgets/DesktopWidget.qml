import QtQuick
import qs.core
import qs.components
import qs.services

// Base for a desktop widget: an optional frosted card (the window blurs behind
// `card`), placed at its saved position. In edit mode the whole widget drags,
// snapping to an 8 px grid and staying on screen; right-click starts edit mode.
Item {
    id: root

    required property string widgetId
    property point defaultPos: Qt.point(80, 120)
    property size area: Qt.size(1920, 1080)       // the screen; widgets stay inside it
    property bool editing: UiState.widgetEdit
    property bool framed: Config.widgets.glass   // card behind the content
    property int padding: 18
    default property alias content: body.data
    readonly property alias card: card

    // Text on a card follows the theme; bare on the wallpaper it is white
    readonly property color fg: framed ? Theme.fgSurface : "white"
    readonly property color fgDim: framed ? Theme.fgSurfaceVariant : Qt.rgba(1, 1, 1, 0.75)

    readonly property var saved: Widgets.position(widgetId)
    function place() {
        x = Qt.binding(() => clampX(saved?.x ?? defaultPos.x));
        y = Qt.binding(() => clampY(saved?.y ?? defaultPos.y));
    }
    implicitWidth: body.childrenRect.width + padding * 2
    implicitHeight: body.childrenRect.height + padding * 2

    function clampX(v) {
        return Math.max(8, Math.min(v, area.width - width - 8));
    }
    function clampY(v) {
        return Math.max(Theme.barHeight + 8, Math.min(v, area.height - height - 8));
    }

    // Pop in
    property real shown: 0
    Component.onCompleted: {
        place();
        shown = 1;
    }
    opacity: shown
    scale: 0.92 + shown * 0.08
    Behavior on shown {
        Spring { preset: "smooth" }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius.large + 4
        color: root.framed ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Theme.glass ? 0.42 : 0.85) : "transparent"
        border.width: root.framed || root.editing ? 1 : 0
        border.color: root.editing ? Theme.primary : Qt.rgba(1, 1, 1, 0.1)
    }

    Item {
        id: body
        x: root.padding
        y: root.padding
        width: childrenRect.width
        height: childrenRect.height
        enabled: !root.editing
    }

    // Edit mode: drag anywhere on the widget
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.editing
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root
        drag.threshold: 2
        onPressed: root.scale = 1.03
        onReleased: {
            root.scale = Qt.binding(() => 0.92 + root.shown * 0.08);
            Widgets.setPosition(root.widgetId, root.clampX(Math.round(root.x / 8) * 8), root.clampY(Math.round(root.y / 8) * 8));
            root.place();
        }
    }
    // Right-click anywhere (outside edit mode) to start editing
    MouseArea {
        anchors.fill: parent
        enabled: !root.editing
        acceptedButtons: Qt.RightButton
        onClicked: UiState.widgetEdit = true
    }

    // Remove (edit mode)
    IconButton {
        visible: root.editing
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: -10
        width: 28
        height: 28
        icon: "close"
        iconSize: 16
        color: Theme.surfaceHighest
        iconColor: Theme.fgSurface
        hoverColor: Theme.error
        onClicked: Widgets.toggle(root.widgetId)
    }
}
