import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.components
import qs.services

// Desktop widgets on the bottom layer (above the wallpaper, below windows).
// The window exists only while a widget is on (or in edit mode) and game mode
// is off. Only the widgets take input; the rest of the screen passes through.
// Widgets that update (system, media progress) pause while windows cover the
// monitor's workspace.
//
// Edit mode (right-click a widget, /widgets, settings): drag to move, ✕ to
// remove, the bar at the top adds widgets back. Esc or Done ends it.
Scope {
    id: root
    required property ShellScreen modelData

    LazyLoader {
        active: Widgets.shown

        PanelWindow {
            id: win
            screen: root.modelData

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
            // Nothing tiled or floating on this monitor's workspace: the desktop is visible
            readonly property bool uncovered: (monitor?.activeWorkspace?.toplevels.values.length ?? 0) === 0
            readonly property bool editing: UiState.widgetEdit

            WlrLayershell.namespace: "somehypr:widgets"
            WlrLayershell.layer: editing ? WlrLayer.Top : WlrLayer.Bottom
            WlrLayershell.keyboardFocus: editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"

            // Input: just the widgets, or the whole screen while editing
            mask: Region {
                item: win.editing ? backdrop : null
                Region { item: clock.item }
                Region { item: media.item?.visible ? media.item : null }
                Region { item: system.item }
                Region { item: notes.item }
            }
            // Frost behind framed cards. Never an empty region (that blurs everything).
            readonly property bool anyFramed: Theme.glass && Config.widgets.glass && (media.item?.visible || system.item || notes.item)
            Region {
                id: blurArea
                Region { item: media.item?.visible ? media.item.card : null; radius: media.item?.card.radius ?? 0 }
                Region { item: system.item?.card ?? null; radius: system.item?.card.radius ?? 0 }
                Region { item: notes.item?.card ?? null; radius: notes.item?.card.radius ?? 0 }
            }
            BackgroundEffect.blurRegion: anyFramed ? blurArea : null

            // Edit mode: dim the desktop, show a grid
            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
                opacity: win.editing ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation { duration: Motion.normal }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: UiState.widgetEdit = false
                }
                focus: win.editing
                Keys.onEscapePressed: UiState.widgetEdit = false
            }

            Loader {
                id: clock
                active: Widgets.isOn("clock")
                sourceComponent: ClockWidget {
                    widgetId: "clock"
                    area: Qt.size(win.width, win.height)
                    defaultPos: Qt.point(64, 88)
                }
            }
            Loader {
                id: media
                active: Widgets.isOn("media")
                sourceComponent: MediaWidget {
                    widgetId: "media"
                    area: Qt.size(win.width, win.height)
                    live: win.uncovered || win.editing
                    defaultPos: Qt.point(64, 300)
                }
            }
            Loader {
                id: system
                active: Widgets.isOn("system")
                sourceComponent: SystemWidget {
                    widgetId: "system"
                    area: Qt.size(win.width, win.height)
                    live: win.uncovered || win.editing
                    defaultPos: Qt.point(win.width - 420, 88)
                }
            }
            Loader {
                id: notes
                active: Widgets.isOn("notes")
                sourceComponent: NotesWidget {
                    widgetId: "notes"
                    area: Qt.size(win.width, win.height)
                    defaultPos: Qt.point(win.width - 380, 300)
                }
            }

            // Edit bar: add/remove widgets, card style, reset, done
            Rectangle {
                id: bar
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.editing ? Theme.barHeight + 16 : -height - 10
                visible: y > -height
                Behavior on y {
                    Spring { preset: "snappy" }
                }
                width: tools.implicitWidth + 16
                height: 52
                radius: height / 2
                color: Theme.surfaceContainer
                border.width: 1
                border.color: Theme.outlineVariant

                Row {
                    id: tools
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: Widgets.available
                        PressButton {
                            id: add
                            required property var modelData
                            readonly property bool on: Widgets.isOn(modelData.id)
                            width: addRow.implicitWidth + 24
                            height: 38
                            radius: 19
                            active: on
                            hoverColor: Theme.surfaceHighest
                            onClicked: Widgets.toggle(modelData.id)
                            Row {
                                id: addRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: add.on ? "check" : add.modelData.icon
                                    size: 18
                                    color: add.on ? Theme.fgPrimary : Theme.fgSurface
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: add.modelData.name
                                    color: add.on ? Theme.fgPrimary : Theme.fgSurface
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: 1
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.outlineVariant
                    }
                    IconButton {
                        width: 38
                        height: 38
                        icon: "texture"
                        active: Config.widgets.glass
                        iconColor: active ? Theme.fgPrimary : Theme.fgSurface
                        hoverColor: Theme.surfaceHighest
                        onClicked: Config.widgets.glass = !Config.widgets.glass
                    }
                    IconButton {
                        width: 38
                        height: 38
                        icon: "restart_alt"
                        iconColor: Theme.fgSurface
                        hoverColor: Theme.surfaceHighest
                        onClicked: Widgets.resetPositions()
                    }
                    PressButton {
                        width: 76
                        height: 38
                        radius: 19
                        color: Theme.primary
                        hoverColor: Theme.primary
                        onClicked: UiState.widgetEdit = false
                        Label {
                            anchors.centerIn: parent
                            text: "Done"
                            color: Theme.fgPrimary
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}
