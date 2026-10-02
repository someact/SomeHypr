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
                width: !shown ? 0 : (UiState.superHeld ? 21 : isActive ? 22 : 10) + 2
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

                // Expressive: the active workspace morphs from a dot into a Material
                // shape (Config.pills.workspaceShape) holding its number. Holding Super
                // turns every slot into that shape with its number: filled when it
                // has windows, an outline when empty.
                readonly property bool held: UiState.superHeld
                MaterialShape {
                    anchors.centerIn: parent
                    width: ws.isActive ? 20 : ws.held ? 18 : ws.isOccupied ? 7 : 5
                    height: width
                    shape: ws.isActive || ws.held ? Config.pills.workspaceShape : "circle"
                    color: ws.isActive ? Theme.primary : ws.held ? (ws.isOccupied ? wsPart.fg : "transparent") : ws.isOccupied ? wsPart.fg : wsPart.floating ? wsPart.fgDim : Theme.outlineVariant
                    borderWidth: ws.held && !ws.isActive && !ws.isOccupied ? 1.5 : wsPart.outline ? 1 : 0
                    borderColor: ws.held && !ws.isActive && !ws.isOccupied ? wsPart.fgDim : wsPart.halo
                    Behavior on width {
                        Spring { preset: "snappy" }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Motion.fast }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    opacity: ws.isActive || ws.held ? 1 : 0
                    visible: opacity > 0
                    text: (ws.wsId - 1) % 10 + 1
                    font.pixelSize: 10
                    font.weight: Theme.font.weightTitle
                    color: ws.isActive ? Theme.fgPrimary : ws.isOccupied ? Theme.surface : wsPart.fgDim
                    style: !ws.isActive && !ws.isOccupied ? wsPart.textStyle : Text.Normal
                    styleColor: wsPart.halo
                    Behavior on opacity {
                        NumberAnimation { duration: Motion.fast }
                    }
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
