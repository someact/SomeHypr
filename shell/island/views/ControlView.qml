import QtQuick
import qs.core
import qs.components
import qs.services

// Quick tiles and sliders. ↑/↓ select, Enter toggles, ←/→ adjust a selected slider.
// The pencil edits the tiles (show, hide, reorder); the grid button switches icon/full tiles.
// Right-click a tile: its detail page here (network, Bluetooth, night light,
// audio devices; Esc or ← goes back) or its page in the settings app.
FocusScope {
    id: root

    implicitWidth: 560
    implicitHeight: col.implicitHeight

    // index into the shown tiles, then sliders
    property int selected: -1
    readonly property int tileCount: tiles.order.length
    readonly property int sliderCount: Brightness.available ? 3 : 2
    readonly property int total: tileCount + sliderCount

    // The open detail page, "" for the tiles
    property string detail: ""
    readonly property var detailTitles: ({ wifi: "Network", bluetooth: "Bluetooth", nightlight: "Night light", audio: "Sound devices" })

    function openTile(id) {
        const t = QuickTiles.tile(id);
        if (!t)
            return;
        if (t.detail !== "") {
            tiles.edit = false;
            detail = t.detail;
        } else if (t.settings !== "") {
            Session.openSettings(t.settings);
            UiState.close();
        }
    }
    Connections {
        target: QuickTiles
        function onOpenDetail(name) {
            root.detail = name;
        }
    }

    function sliderAt(i) {
        return [volume, mic, brightness][i];
    }
    function handleKey(event) {
        const k = event.key;
        if (detail !== "") {
            if (page.item?.handleKey && page.item.handleKey(event))
                return true;
            if (k === Qt.Key_Escape || k === Qt.Key_Backspace) {
                detail = "";
                return true;
            }
            return UiState.navKey(event);
        }
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
            IconButton {
                id: back
                visible: root.detail !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 26
                iconSize: 18
                icon: "arrow_back"
                onClicked: root.detail = ""
            }
            Label {
                visible: root.detail !== ""
                anchors.left: back.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.detailTitles[root.detail] ?? ""
                font.weight: Theme.font.weightTitle
            }
            Label {
                visible: root.detail === ""
                anchors.verticalCenter: parent.verticalCenter
                text: tiles.edit ? "Click to show or hide · drag to reorder" : ""
                color: Theme.fgIslandDim
                font.pixelSize: Theme.font.small
            }
            Row {
                visible: root.detail === ""
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

        Loader {
            id: page
            active: root.detail !== ""
            visible: active
            width: parent.width
            height: item ? item.implicitHeight : 0
            sourceComponent: ({ wifi: networkPage, bluetooth: bluetoothPage, nightlight: nightPage, audio: audioPage })[root.detail] ?? null
            onLoaded: {
                item.width = Qt.binding(() => page.width);
                item.opacity = 0;
                pageIn.restart();
            }
            NumberAnimation {
                id: pageIn
                target: page.item
                property: "opacity"
                to: 1
                duration: Motion.normal
                easing.type: Easing.OutCubic
            }
        }

        TileGrid {
            id: tiles
            visible: root.detail === ""
            width: parent.width
            selected: root.selected
            onRightClicked: id => root.openTile(id)
        }

        Slider {
            id: volume
            visible: root.detail === ""
            width: parent.width
            icon: Audio.icon
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
            trackColor: root.selected === root.tileCount ? Theme.islandRaisedHover : Theme.islandRaised
        }
        Slider {
            id: mic
            visible: root.detail === ""
            width: parent.width
            icon: Audio.micIcon
            value: Audio.micVolume
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
            trackColor: root.selected === root.tileCount + 1 ? Theme.islandRaisedHover : Theme.islandRaised
        }
        Slider {
            id: brightness
            visible: Brightness.available && root.detail === ""
            width: parent.width
            icon: "light_mode"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
            trackColor: root.selected === root.tileCount + 2 ? Theme.islandRaisedHover : Theme.islandRaised
        }
    }

    Component {
        id: networkPage
        NetworkDetail {}
    }
    Component {
        id: bluetoothPage
        BluetoothDetail {}
    }
    Component {
        id: nightPage
        NightLightDetail {}
    }
    Component {
        id: audioPage
        AudioDevices {}
    }
}
