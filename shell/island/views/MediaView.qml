import QtQuick
import Quickshell.Services.Mpris
import qs.core
import qs.components
import qs.services

// Now playing. Enter/Space play-pause, ↑/↓ previous/next, click a player chip to switch.
FocusScope {
    id: root

    implicitWidth: 520
    implicitHeight: Media.player ? 156 : 80

    Component.onCompleted: Media.watchers++
    Component.onDestruction: Media.watchers--

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            Media.toggle();
            return true;
        case Qt.Key_Up:
            Media.previous();
            return true;
        case Qt.Key_Down:
            Media.next();
            return true;
        }
        return UiState.navKey(event);
    }

    Label {
        anchors.centerIn: parent
        visible: !Media.player
        text: "Nothing playing"
        color: Theme.fgIslandDim
    }

    Row {
        visible: Media.player !== null
        anchors.fill: parent
        spacing: 16

        Cover {
            width: 148
            height: 148
            radius: Theme.radius.large
            source: Media.art
        }

        Column {
            width: parent.width - 164
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Label {
                width: parent.width
                text: Media.title
                font.pixelSize: Theme.font.large
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                text: Media.artist
                color: Theme.fgIslandDim
            }

            // progress
            Item {
                width: parent.width
                height: 22
                Rectangle {
                    id: bar
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.islandRaised
                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: Theme.fgIsland
                        width: parent.width * Media.progress
                        Behavior on width {
                            Spring { preset: "gentle" }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: Media.player?.canSeek ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => Media.seek(event.x / width)
                }
            }
            Row {
                width: parent.width
                Label {
                    width: parent.width / 2
                    mono: true
                    font.pixelSize: Theme.font.small
                    color: Theme.fgIslandDim
                    text: root.fmt(Media.player?.position ?? 0)
                }
                Label {
                    width: parent.width / 2
                    mono: true
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.font.small
                    color: Theme.fgIslandDim
                    text: root.fmt(Media.length)
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                IconButton {
                    icon: "skip_previous"
                    iconSize: 26
                    width: 40
                    height: 40
                    onClicked: Media.previous()
                }
                IconButton {
                    icon: Media.isPlaying ? "pause" : "play_arrow"
                    iconSize: 30
                    width: 48
                    height: 48
                    color: Theme.islandRaised
                    onClicked: Media.toggle()
                }
                IconButton {
                    icon: "skip_next"
                    iconSize: 26
                    width: 40
                    height: 40
                    onClicked: Media.next()
                }
            }
        }
    }

    // Player switcher, when there is more than one
    Row {
        visible: Media.players.length > 1
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 4
        Repeater {
            model: Media.players
            PressButton {
                required property MprisPlayer modelData
                width: chip.implicitWidth + 16
                height: 22
                color: Theme.islandRaised
                active: Media.player === modelData
                onClicked: Media.last = modelData
                Label {
                    id: chip
                    anchors.centerIn: parent
                    text: modelData.identity
                    font.pixelSize: Theme.font.small
                    color: parent.active ? Theme.fgPrimary : Theme.fgIsland
                }
            }
        }
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        const m = Math.floor(s / 60);
        return m + ":" + String(s % 60).padStart(2, "0");
    }
}
