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

    Row {
        id: workspaces
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

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
                width: UiState.superHeld ? 16 : isActive ? 22 : 10
                height: 18
                Behavior on width {
                    Spring { preset: "snappy" }
                }

                Rectangle {
                    anchors.centerIn: parent
                    visible: !UiState.superHeld
                    width: ws.isActive ? 18 : 6
                    height: 6
                    radius: 3
                    color: ws.isActive ? Theme.primary : ws.isOccupied ? Theme.fgPill : Theme.pillsFloating ? Theme.fgPillDim : Theme.outlineVariant
                    border.width: Theme.pillsFloating && !Theme.pillShadow ? 1 : 0
                    border.color: Theme.pillHalo
                    Behavior on width {
                        Spring { preset: "snappy" }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: UiState.superHeld
                    text: (ws.wsId - 1) % 10 + 1
                    mono: true
                    font.pixelSize: Theme.font.small
                    color: ws.isActive ? Theme.primary : ws.isOccupied ? Theme.fgPill : Theme.fgPillDim
                    style: Theme.pillTextStyle
                    styleColor: Theme.pillHalo
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HyprData.focusWorkspace(ws.wsId)
                }
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        visible: HyprData.activeTitle !== ""
        width: 1
        height: 14
        color: Theme.pillsFloating ? Theme.fgPillDim : Theme.outlineVariant
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        visible: HyprData.activeTitle !== ""
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
            color: Theme.fgPill
            style: Theme.pillTextStyle
            styleColor: Theme.pillHalo
            font.pixelSize: Theme.font.small
        }
    }

    WheelHandler {
        target: null
        parent: win.pill
        onWheel: event => HyprData.focusWorkspace(event.angleDelta.y > 0 ? "r-1" : "r+1")
    }
}
