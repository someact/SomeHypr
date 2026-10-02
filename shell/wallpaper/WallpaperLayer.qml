import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Plain image wallpaper on the background layer. Video wallpapers (mpvpaper)
// arrive in Phase 3; until then this layer steps aside for them.
PanelWindow {
    required property ShellScreen modelData
    screen: modelData

    visible: !Wallpaper.isVideo
    WlrLayershell.namespace: "somehypr:wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.surface

    Image {
        anchors.fill: parent
        source: Wallpaper.path !== "" ? Paths.url(Wallpaper.path) : ""
        sourceSize: Qt.size(parent.width, parent.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        retainWhileLoading: true
        cache: false
    }
}
