import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.components
import qs.services

// Super+G game overlay: draggable widgets over everything, fullscreen games
// included. Open, it dims the screen and takes the keyboard; closed, pinned
// widgets and the crosshair stay on screen and every click passes through.
// The window exists only while something is showing.
Scope {
    id: root

    readonly property var widgets: [
        { id: "crosshair", icon: "point_scan", name: "Crosshair" },
        { id: "fps", icon: "speed", name: "FPS limit" },
        { id: "resources", icon: "monitoring", name: "Resources" },
        { id: "mixer", icon: "graphic_eq", name: "Mixer" },
        { id: "notes", icon: "sticky_note_2", name: "Notes" }
    ]
    readonly property bool hasPinned: Config.overlay.pinned.length > 0
    property ShellScreen screen: Quickshell.screens[0]

    Connections {
        target: UiState
        function onOverlayChanged() {
            if (UiState.overlay) {
                root.screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
                UiState.close();
                UiState.overview = false;
            } else {
                unload.restart();
            }
        }
    }
    Timer {
        id: unload
        interval: 300
    }

    LazyLoader {
        active: UiState.overlay || unload.running || root.hasPinned || Config.overlay.crosshair.enabled

        PanelWindow {
            id: win

            readonly property bool shown: UiState.overlay

            function isOpen(id) {
                return shown ? Config.overlay.open.includes(id) : Config.overlay.pinned.includes(id);
            }
            function toggle(id) {
                const open = Config.overlay.open;
                Config.overlay.open = open.includes(id) ? open.filter(w => w !== id) : [...open, id];
            }

            screen: root.screen
            WlrLayershell.namespace: "somehypr:overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"

            // Closed: no input region at all, so clicks reach the game
            mask: Region {
                item: win.shown ? backdrop : null
            }

            // Frost behind the bar and the open cards (no xray on this layer, so it
            // blurs the game itself). Game mode turns compositor blur off; while the
            // overlay is open it is switched back on (hypr/modes/gamemode.lua).
            Region {
                id: frost
                Region { item: bar.frost; radius: bar.frostRadius }
                Region { item: crosshairCard.item?.card.frost ?? null; radius: crosshairCard.item?.card.frostRadius ?? 0 }
                Region { item: fpsCard.item?.card.frost ?? null; radius: fpsCard.item?.card.frostRadius ?? 0 }
                Region { item: resourcesCard.item?.card.frost ?? null; radius: resourcesCard.item?.card.frostRadius ?? 0 }
                Region { item: mixerCard.item?.card.frost ?? null; radius: mixerCard.item?.card.frostRadius ?? 0 }
                Region { item: notesCard.item?.card.frost ?? null; radius: notesCard.item?.card.frostRadius ?? 0 }
            }
            BackgroundEffect.blurRegion: Theme.glass && win.shown ? frost : null

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)
                opacity: win.shown ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Motion.normal }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: UiState.overlay = false
                }
            }

            Crosshair {
                anchors.centerIn: parent
                visible: Config.overlay.crosshair.enabled
            }

            // Widgets. Keys typed into a widget (notes) reach this only if unused.
            Item {
                anchors.fill: parent
                focus: win.shown
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) {
                        UiState.overlay = false;
                        e.accepted = true;
                    } else if (e.key >= Qt.Key_1 && e.key < Qt.Key_1 + root.widgets.length) {
                        win.toggle(root.widgets[e.key - Qt.Key_1].id);
                        e.accepted = true;
                    }
                }
                Loader {
                    id: crosshairCard
                    active: win.isOpen("crosshair")
                    sourceComponent: CrosshairCard {
                        widgetId: "crosshair"
                        interactive: win.shown
                        defaultPos: Qt.point(win.width - 340, 120)
                    }
                }
                Loader {
                    id: fpsCard
                    active: win.isOpen("fps")
                    sourceComponent: FpsCard {
                        widgetId: "fps"
                        interactive: win.shown
                        defaultPos: Qt.point(win.width - 340, 480)
                    }
                }
                Loader {
                    id: resourcesCard
                    active: win.isOpen("resources")
                    sourceComponent: ResourcesCard {
                        widgetId: "resources"
                        interactive: win.shown
                        defaultPos: Qt.point(40, 120)
                    }
                }
                Loader {
                    id: mixerCard
                    active: win.isOpen("mixer")
                    sourceComponent: MixerCard {
                        widgetId: "mixer"
                        interactive: win.shown
                        defaultPos: Qt.point(40, 400)
                    }
                }
                Loader {
                    id: notesCard
                    active: win.isOpen("notes")
                    sourceComponent: NotesCard {
                        widgetId: "notes"
                        interactive: win.shown
                        defaultPos: Qt.point(Math.round(win.width / 2 - 160), 160)
                    }
                }
            }

            // Tool bar: widgets, quick record, close
            Glass {
                id: bar
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.shown ? 18 : -height - 10
                Behavior on y {
                    Spring { preset: "snappy" }
                }
                width: tools.implicitWidth + 12
                height: 48
                radius: height / 2
                tint: Qt.rgba(0, 0, 0, Theme.glass ? 0.5 : 0.8)

                Row {
                    id: tools
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: root.widgets
                        IconButton {
                            required property var modelData
                            width: 40
                            height: 36
                            radius: 18
                            iconSize: 19
                            icon: modelData.icon
                            active: Config.overlay.open.includes(modelData.id)
                            onClicked: win.toggle(modelData.id)
                        }
                    }
                    Rectangle {
                        width: 1
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }
                    // Record the screen (with sound); the island shows the timer
                    PressButton {
                        width: Recorder.active ? recLabel.implicitWidth + 46 : 40
                        height: 36
                        radius: 18
                        active: Recorder.active
                        activeColor: "#ff453a"
                        onClicked: Recorder.toggleScreen(true)
                        Behavior on width {
                            Spring { preset: "snappy" }
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: Recorder.active ? "stop_circle" : "screen_record"
                                size: 19
                                fill: Recorder.active ? 1 : 0
                            }
                            Label {
                                id: recLabel
                                anchors.verticalCenter: parent.verticalCenter
                                visible: Recorder.active
                                mono: true
                                text: Recorder.elapsedText
                            }
                        }
                    }
                    IconButton {
                        width: 40
                        height: 36
                        radius: 18
                        iconSize: 19
                        icon: "close"
                        onClicked: UiState.overlay = false
                    }
                }
            }

        }
    }
}
