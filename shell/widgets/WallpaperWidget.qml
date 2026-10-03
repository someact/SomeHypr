import QtQuick
import qs.core
import qs.components
import qs.services

// The current wallpaper: thumbnail and name, shuffle from the wallpaper folder,
// light/dark, and the island's picker.
DesktopWidget {
    id: root

    readonly property string name: Wallpaper.path.split("/").pop()

    Column {
        width: 240
        spacing: 10
        Cover {
            width: parent.width
            height: Math.round(width * 9 / 16)
            radius: Theme.radius.normal
            source: Thumbs.url(Wallpaper.path)
            fallbackIcon: "wallpaper"
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: UiState.open("wallpaper")
            }
        }
        Label {
            width: parent.width
            text: root.name !== "" ? root.name : "No wallpaper"
            color: root.fg
            font.pixelSize: Theme.font.small
        }
        Row {
            spacing: 4
            IconButton {
                icon: "shuffle"
                iconColor: root.fg
                hoverColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
                onClicked: Wallpaper.random()
            }
            IconButton {
                icon: Wallpaper.mode === "dark" ? "dark_mode" : "light_mode"
                iconColor: root.fg
                hoverColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
                onClicked: Wallpaper.toggleLightDark()
            }
            IconButton {
                icon: "photo_library"
                iconColor: root.fg
                hoverColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
                onClicked: UiState.open("wallpaper")
            }
        }
    }
}
