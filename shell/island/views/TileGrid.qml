import QtQuick
import qs.core
import qs.components
import qs.services

// The Control view's quick tiles (services/QuickTiles.qml). One delegate per
// tile id for the life of the view; each sits at its slot with a spring, so a
// tile shown, hidden or dragged slides instead of the grid being rebuilt.
//
// Edit mode: shown tiles first, then a "Hidden" row; click shows or hides a
// tile, drag a shown one to reorder (committed on release).
Item {
    id: grid

    property bool edit: false
    property int selected: -1                    // keyboard selection, index into `order`
    readonly property bool compact: Config.control.tileStyle === "icon"

    // Shown tiles in order; a local copy while dragging
    property var order: QuickTiles.shown
    readonly property var hiddenTiles: edit ? QuickTiles.hidden : []

    readonly property int spacing: 8
    readonly property int columns: compact ? 8 : 2
    readonly property real tileW: (width - (columns - 1) * spacing) / columns
    readonly property real tileH: 52
    readonly property real pitchX: tileW + spacing
    readonly property real pitchY: tileH + spacing
    readonly property int shownRows: Math.ceil(order.length / columns)
    readonly property int hiddenRows: Math.ceil(hiddenTiles.length / columns)
    readonly property real labelH: 26
    readonly property real hiddenTop: shownRows * pitchY + labelH

    signal rightClicked(string id)

    implicitHeight: {
        const shownH = Math.max(0, shownRows * pitchY - spacing);
        if (!edit)
            return shownH;
        return hiddenTop + Math.max(tileH, hiddenRows * pitchY - spacing);
    }

    function run(i) {
        QuickTiles.tile(order[i])?.run();
    }
    function toggleShown(id) {
        if (QuickTiles.shown.includes(id))
            QuickTiles.hide(id);
        else
            QuickTiles.show(id);
    }
    function dragTo(id, px, py) {
        const col = Math.max(0, Math.min(columns - 1, Math.floor(px / pitchX)));
        const row = Math.max(0, Math.min(shownRows - 1, Math.floor(py / pitchY)));
        const target = Math.min(row * columns + col, order.length - 1);
        const from = order.indexOf(id);
        if (from < 0 || target === from)
            return;
        const next = order.filter(t => t !== id);
        next.splice(target, 0, id);
        order = next;
    }
    function commit() {
        QuickTiles.setOrder(order);
        order = Qt.binding(() => QuickTiles.shown);
    }

    Label {
        visible: grid.edit
        y: grid.shownRows * grid.pitchY + 4
        text: grid.hiddenTiles.length > 0 ? "Hidden · click to add" : "Every tile is shown"
        color: Theme.fgIslandDim
        font.pixelSize: Theme.font.small
    }

    Repeater {
        model: QuickTiles.ids

        Item {
            id: cell
            required property string modelData
            readonly property var tile: QuickTiles.tile(modelData)
            readonly property int shownIdx: grid.order.indexOf(modelData)
            readonly property int hiddenIdx: grid.hiddenTiles.indexOf(modelData)
            readonly property bool isShown: shownIdx >= 0
            readonly property real slotX: ((isShown ? shownIdx : hiddenIdx) % grid.columns) * grid.pitchX
            readonly property real slotY: isShown ? Math.floor(shownIdx / grid.columns) * grid.pitchY : grid.hiddenTop + Math.floor(hiddenIdx / grid.columns) * grid.pitchY
            readonly property bool present: isShown || hiddenIdx >= 0

            // Dragging follows the pointer; springs only once the tile has a place,
            // so a tile that appears starts at its slot instead of flying in
            property bool dragging: false
            property real dragX: 0
            property real dragY: 0
            property bool placed: false
            onPresentChanged: {
                placed = false;
                if (present)
                    Qt.callLater(() => cell.placed = cell.present);
            }
            Component.onCompleted: placed = present

            visible: present
            z: dragging ? 2 : 0
            x: dragging ? dragX : slotX
            y: dragging ? dragY : slotY
            width: grid.tileW
            height: grid.tileH
            Behavior on x {
                enabled: cell.placed && !cell.dragging
                Spring { preset: "snappy" }
            }
            Behavior on y {
                enabled: cell.placed && !cell.dragging
                Spring { preset: "snappy" }
            }
            Behavior on width {
                enabled: cell.placed
                Spring { preset: "snappy" }
            }

            Toggle {
                anchors.fill: parent
                compact: grid.compact
                icon: cell.tile.icon
                title: cell.tile.title
                subtitle: cell.tile.subtitle
                active: cell.tile.active && !grid.edit
                highlighted: !grid.edit && grid.selected === cell.shownIdx
                opacity: grid.edit && !cell.isShown ? 0.45 : 1
                onClicked: cell.tile.run()
                onRightClicked: grid.rightClicked(cell.modelData)
                Behavior on opacity {
                    NumberAnimation { duration: Motion.fast }
                }
            }

            // Edit badge: remove on shown tiles, add on hidden ones
            Rectangle {
                visible: grid.edit
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -3
                width: 18
                height: 18
                radius: 9
                color: cell.isShown ? Theme.islandRaisedHover : Theme.primary
                Icon {
                    anchors.centerIn: parent
                    name: cell.isShown ? "remove" : "add"
                    size: 14
                    color: cell.isShown ? Theme.fgIsland : Theme.fgPrimary
                }
            }

            // Edit mode takes the pointer: click shows/hides, drag reorders
            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                enabled: grid.edit
                cursorShape: cell.dragging ? Qt.ClosedHandCursor : cell.isShown ? Qt.OpenHandCursor : Qt.PointingHandCursor
                preventStealing: true
                property point start
                property bool moved: false
                onPressed: event => {
                    start = Qt.point(event.x, event.y);
                    moved = false;
                }
                onPositionChanged: event => {
                    if (!pressed || !cell.isShown)
                        return;
                    if (!moved && Math.hypot(event.x - start.x, event.y - start.y) < 6)
                        return;
                    if (!moved) {
                        moved = true;
                        cell.dragX = cell.x;
                        cell.dragY = cell.y;
                        cell.dragging = true;
                    }
                    const p = mapToItem(grid, event.x, event.y);
                    cell.dragX = p.x - start.x - anchors.margins;
                    cell.dragY = p.y - start.y - anchors.margins;
                    grid.dragTo(cell.modelData, p.x, p.y);
                }
                onReleased: {
                    if (cell.dragging) {
                        cell.dragging = false;
                        grid.commit();
                    } else if (!moved) {
                        grid.toggleShown(cell.modelData);
                    }
                }
            }
        }
    }
}
