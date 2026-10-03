import QtQuick
import qs.core
import qs.components
import qs.services

// Quick tiles and sliders. ↑/↓ select, Enter toggles, ←/→ adjust a selected slider.
// The pencil edits the tiles (show, hide, reorder); the grid button switches icon/full tiles.
FocusScope {
    id: root

    implicitWidth: 560
    implicitHeight: col.implicitHeight

    // index into the shown tiles, then sliders
    property int selected: -1
    readonly property int tileCount: tiles.order.length
    readonly property int sliderCount: Brightness.available ? 3 : 2
    readonly property int total: tileCount + sliderCount

    function sliderAt(i) {
        return [volume, mic, brightness][i];
    }
    function handleKey(event) {
        const k = event.key;
        if (tiles.edit && (k === Qt.Key_Escape || k === Qt.Key_Return || k === Qt.Key_Enter)) {
            tiles.edit = false;
            return true;
        }
        if (k === Qt.Key_Down || k === Qt.Key_Up) {
            selected = selected < 0 ? 0 : (selected + (k === Qt.Key_Down ? 1 : -1) + total) % total;
            return true;
        }
        if ((k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) && selected >= 0 && selected < tileCount) {
            tiles.run(selected);
            return true;
        }
        if ((k === Qt.Key_Left || k === Qt.Key_Right) && selected >= tileCount) {
            const s = sliderAt(selected - tileCount);
            s.set(s.value + (k === Qt.Key_Right ? 0.05 : -0.05));
            return true;
        }
        return UiState.navKey(event);
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        // Edit and tile style
        Item {
            width: parent.width
            height: 26
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: tiles.edit ? "Click to show or hide · drag to reorder" : ""
                color: Theme.fgIslandDim
                font.pixelSize: Theme.font.small
            }
            Row {
                anchors.right: parent.right
                spacing: 4
                IconButton {
                    width: 30
                    height: 26
                    iconSize: 17
                    icon: Config.control.tileStyle === "icon" ? "view_agenda" : "grid_view"
                    iconColor: Theme.fgIslandDim
                    onClicked: Config.control.tileStyle = Config.control.tileStyle === "icon" ? "full" : "icon"
                }
                IconButton {
                    width: 30
                    height: 26
                    iconSize: 17
                    icon: tiles.edit ? "check" : "edit"
                    active: tiles.edit
                    activeColor: Theme.islandRaisedHover
                    iconColor: tiles.edit ? Theme.fgIsland : Theme.fgIslandDim
                    onClicked: tiles.edit = !tiles.edit
                }
            }
        }

        TileGrid {
            id: tiles
            width: parent.width
            selected: root.selected
        }

        Slider {
            id: volume
            width: parent.width
            icon: Audio.icon
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
            trackColor: root.selected === root.tileCount ? Theme.islandRaisedHover : Theme.islandRaised
        }
        Slider {
            id: mic
            width: parent.width
            icon: Audio.micIcon
            value: Audio.micVolume
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
            trackColor: root.selected === root.tileCount + 1 ? Theme.islandRaisedHover : Theme.islandRaised
        }
        Slider {
            id: brightness
            visible: Brightness.available
            width: parent.width
            icon: "light_mode"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
            trackColor: root.selected === root.tileCount + 2 ? Theme.islandRaisedHover : Theme.islandRaised
        }
    }
}
