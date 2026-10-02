import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.core
import qs.components
import qs.services

// Top-right parts: tray · keyboard layout, network, Bluetooth, volume · date/time.
CornerWindow {
    id: win
    left: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PillPart {
        id: trayPart
        style: Config.pills.tray
        shown: Tray.items.length > 0

        Repeater {
            model: Tray.items
            MouseArea {
                id: trayItem
                required property SystemTrayItem modelData
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    if (event.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                    } else if (event.button === Qt.RightButton || modelData.onlyMenu) {
                        if (modelData.hasMenu) {
                            const p = mapToItem(win.contentItem, 0, height + 6);
                            modelData.display(win, p.x, p.y);
                        }
                    } else {
                        modelData.activate();
                    }
                }
                onWheel: event => modelData.scroll(event.angleDelta.y / 120, false)
                IconImage {
                    anchors.fill: parent
                    source: trayItem.modelData.icon
                }
            }
        }
    }

    PillPart {
        id: statusPart
        style: Config.pills.status

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: KbLayout.code
            visible: text !== ""
            font.pixelSize: Theme.font.small
            font.weight: Theme.font.weightTitle
            color: statusPart.fg
            style: statusPart.textStyle
            styleColor: statusPart.halo
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: KbLayout.next()
            }
        }
        StatusIcon {
            part: statusPart
            name: Network.icon
        }
        StatusIcon {
            part: statusPart
            name: BluetoothState.icon
            visible: BluetoothState.available
            dim: !BluetoothState.enabled
        }
        StatusIcon {
            part: statusPart
            name: Audio.icon
            onWheel: up => Audio.setVolume(Audio.volume + (up ? 0.02 : -0.02))
            onMiddle: Audio.toggleMute()
        }
    }

    PillPart {
        id: clockPart
        style: Config.pills.clock

        Label {
            anchors.verticalCenter: parent.verticalCenter
            // The island shows the time while idle; don't repeat it here
            text: UiState.ambient === "clock" ? Qt.formatDateTime(clock.date, Config.clock.dateFormat) : Qt.formatDateTime(clock.date, Config.clock.dateFormat + "  " + Config.clock.format)
            font.pixelSize: Theme.font.small
            font.weight: Theme.font.weightTitle
            color: clockPart.fg
            style: clockPart.textStyle
            styleColor: clockPart.halo
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: UiState.toggle("notifications")
            }
        }
    }

    component StatusIcon: Icon {
        id: si
        required property PillPart part
        property bool dim: false
        signal wheel(bool up)
        signal middle
        anchors.verticalCenter: parent.verticalCenter
        size: 16
        color: dim ? part.fgDim : part.fg
        style: part.textStyle
        styleColor: part.halo
        MouseArea {
            anchors.fill: parent
            anchors.margins: -3
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: event => event.button === Qt.MiddleButton ? si.middle() : UiState.toggle("control")
            onWheel: event => si.wheel(event.angleDelta.y > 0)
        }
    }
}
