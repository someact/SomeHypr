import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Image wallpaper on the background layer, crossfading between changes.
// Video wallpapers are played by mpvpaper (services/Wallpaper.qml); this layer
// hides while one is active.
PanelWindow {
    id: win
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

    readonly property string source: Wallpaper.path !== "" && !Wallpaper.isVideo ? Paths.url(Wallpaper.path) : ""
    property bool frontIsA: true

    // Load the new image into the hidden slot; fade it in once decoded
    onSourceChanged: {
        const back = frontIsA ? b : a;
        back.source = source;
    }
    Component.onCompleted: a.source = source

    component Slot: Image {
        anchors.fill: parent
        sourceSize: Qt.size(win.width, win.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.reduced ? 0 : 450
                easing.type: Easing.InOutQuad
            }
        }
    }

    Slot {
        id: a
        opacity: win.frontIsA ? 1 : 0
        onStatusChanged: if (status === Image.Ready && !win.frontIsA) win.frontIsA = true
    }
    Slot {
        id: b
        opacity: win.frontIsA ? 0 : 1
        onStatusChanged: if (status === Image.Ready && win.frontIsA) win.frontIsA = false
    }
}
