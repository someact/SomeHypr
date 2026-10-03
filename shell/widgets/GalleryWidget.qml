import QtQuick
import Quickshell
import Qt.labs.folderlistmodel
import qs.core
import qs.components
import qs.services

// Slideshow of the pictures in a folder (widgets.galleryDir, default
// ~/Pictures), one every widgets.galleryInterval seconds, only while the
// desktop is visible. Click: next; double-click: open the picture.
DesktopWidget {
    id: root

    property bool live: true
    readonly property string folder: Config.widgets.galleryDir || Paths.home + "/Pictures"
    property int index: 0

    FolderListModel {
        id: files
        folder: Paths.url(root.folder)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif", "*.bmp", "*.JPG", "*.PNG"]
        showDirs: false
        sortField: FolderListModel.Time
        onCountChanged: if (root.index >= count) root.index = 0
    }
    readonly property string current: files.count > 0 ? files.get(index % files.count, "filePath") : ""

    Timer {
        interval: Math.max(5, Config.widgets.galleryInterval) * 1000
        repeat: true
        running: root.live && files.count > 1
        onTriggered: root.index = (root.index + 1) % files.count
    }

    // Two slots crossfade; each decodes at the widget's size only
    property bool flip: false
    onCurrentChanged: {
        flip = !flip;
        (flip ? b : a).source = current !== "" ? Paths.url(current) : "";
    }

    Cover {
        width: 300
        height: 220
        radius: Theme.radius.normal
        fallbackIcon: files.count === 0 ? "image_not_supported" : ""
        Image {
            id: a
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(600, 440)
            asynchronous: true
            opacity: !root.flip && status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 600 }
            }
            onOpacityChanged: if (opacity === 0 && root.flip) source = ""
        }
        Image {
            id: b
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(600, 440)
            asynchronous: true
            opacity: root.flip && status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 600 }
            }
            onOpacityChanged: if (opacity === 0 && !root.flip) source = ""
        }
        Label {
            visible: files.count === 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "No pictures in " + root.folder.replace(Paths.home, "~") + " · pick a folder in Settings → Desktop"
            color: Theme.fgIslandDim
            font.pixelSize: Theme.font.small
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: if (files.count > 1) root.index = (root.index + 1) % files.count
            onDoubleClicked: if (root.current !== "") Quickshell.execDetached(["xdg-open", root.current])
        }
    }
}
