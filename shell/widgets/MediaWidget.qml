import QtQuick
import qs.core
import qs.components
import qs.services

// Now playing: art, title, progress and controls. Hidden while nothing plays
// (shown as a placeholder in edit mode so it can still be placed).
DesktopWidget {
    id: root

    property bool live: true        // false while windows cover the desktop: no progress updates
    visible: Media.active || editing

    // Progress ticks only while someone can see it
    readonly property bool watching: live && Media.active
    property bool counted: false
    function sync() {
        if (watching !== counted) {
            Media.watchers += watching ? 1 : -1;
            counted = watching;
        }
    }
    onWatchingChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (counted) Media.watchers--

    Row {
        spacing: 16
        Cover {
            width: 88
            height: 88
            radius: Theme.radius.normal
            source: Media.art
        }
        Column {
            width: 220
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Label {
                width: parent.width
                text: Media.active ? Media.title : "Nothing playing"
                color: root.fg
                font.pixelSize: Theme.font.large
                font.weight: Theme.font.weightTitle
            }
            Label {
                width: parent.width
                text: Media.artist
                color: root.fgDim
            }
            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)
                Rectangle {
                    height: parent.height
                    radius: 2
                    width: parent.width * Media.progress
                    color: Theme.primary
                }
            }
            Row {
                topPadding: 4
                spacing: 4
                IconButton {
                    icon: "skip_previous"
                    iconColor: root.fg
                    hoverColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
                    onClicked: Media.previous()
                }
                IconButton {
                    icon: Media.isPlaying ? "pause" : "play_arrow"
                    active: true
                    onClicked: Media.toggle()
                }
                IconButton {
                    icon: "skip_next"
                    iconColor: root.fg
                    hoverColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
                    onClicked: Media.next()
                }
            }
        }
    }
}
