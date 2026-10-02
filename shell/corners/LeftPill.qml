import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// Top-left: workspaces of the current group, then the focused app.
CornerWindow {
    id: win
    left: true

    PillPart {
        id: wsPart
        style: Config.pills.workspaces
        spacing: 0

        Repeater {
            model: HyprData.groupSize
            Item {
                id: ws
                required property int index
                readonly property int wsId: HyprData.groupStart + index
                readonly property bool isActive: HyprData.activeId === wsId
                readonly property bool isOccupied: {
                    Hyprland.workspaces.values; // re-evaluate on workspace list changes
                    return HyprData.occupied(wsId);
                }
                // Only workspaces with windows and the active one (unless "show empty"
                // is on, or Super is held). The 10 slots stay; a hidden one springs
                // to zero width, so nothing is rebuilt and they slide in and out.
                readonly property bool shown: isActive || isOccupied || Config.pills.showEmpty || UiState.superHeld
                width: !shown ? 0 : (UiState.superHeld ? 16 : isActive ? 22 : 10) + 2
                height: 20
                opacity: shown ? 1 : 0
                scale: shown ? 1 : 0.4
                Behavior on width {
                    Spring { preset: "snappy" }
                }
                Behavior on scale {
                    Spring { preset: "snappy" }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Motion.fast }
                }

                // Expressive: the active workspace morphs from a dot into a
                // Material shape (Config.pills.workspaceShape) holding its number
                MaterialShape {
                    anchors.centerIn: parent
                    visible: !UiState.superHeld
                    width: ws.isActive ? 20 : ws.isOccupied ? 7 : 5
                    height: width
                    shape: ws.isActive ? Config.pills.workspaceShape : "circle"
                    color: ws.isActive ? Theme.primary : ws.isOccupied ? wsPart.fg : wsPart.floating ? wsPart.fgDim : Theme.outlineVariant
                    borderWidth: wsPart.outline ? 1 : 0
                    borderColor: wsPart.halo
                    Behavior on width {
                        Spring { preset: "snappy" }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: ws.isActive && !UiState.superHeld
                    text: (ws.wsId - 1) % 10 + 1
                    font.pixelSize: 10
                    font.weight: Theme.font.weightTitle
                    color: Theme.fgPrimary
                }
                Label {
                    anchors.centerIn: parent
                    visible: UiState.superHeld
                    text: (ws.wsId - 1) % 10 + 1
                    mono: true
                    font.pixelSize: Theme.font.small
                    color: ws.isActive ? Theme.primary : ws.isOccupied ? wsPart.fg : wsPart.fgDim
                    style: wsPart.textStyle
                    styleColor: wsPart.halo
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: ws.shown
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HyprData.focusWorkspace(ws.wsId)
                }
            }
        }
    }

    PillPart {
        id: titlePart
        style: Config.pills.title
        shown: HyprData.activeTitle !== ""
        spacing: 6

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: HyprData.activeAppId !== "" ? HyprData.appIcon(HyprData.activeAppId) : ""
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 300)
            text: HyprData.activeTitle
            color: titlePart.fg
            style: titlePart.textStyle
            styleColor: titlePart.halo
            font.pixelSize: Theme.font.small
        }
    }

    WheelHandler {
        target: null
        parent: win.bar
        onWheel: event => HyprData.focusWorkspace(event.angleDelta.y > 0 ? "r-1" : "r+1")
    }
}
