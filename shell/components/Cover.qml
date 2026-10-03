import QtQuick
import Quickshell.Widgets
import qs.core

// Rounded image (album art, notification image) with an icon fallback.
// ClippingRectangle clips in the shader, so there is no offscreen layer.
ClippingRectangle {
    id: root
    property string source
    property string fallbackIcon: "music_note"
    readonly property bool ready: img.status === Image.Ready

    color: Theme.islandRaised
    radius: Theme.radius.small

    Image {
        id: img
        anchors.fill: parent
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: root.ready
        source: root.source
        // Players can announce an art file before it is written: retry a few times
        property int tries: 0
        onStatusChanged: if (status === Image.Error && tries < 3) retry.start()
        Connections {
            target: root
            function onSourceChanged() {
                img.tries = 0;
                retry.stop();
            }
        }
        Timer {
            id: retry
            interval: 700
            onTriggered: {
                img.tries++;
                img.source = "";
                img.source = Qt.binding(() => root.source);
            }
        }
    }
    Icon {
        anchors.centerIn: parent
        visible: !root.ready && root.fallbackIcon !== ""
        name: root.fallbackIcon
        size: Math.max(12, root.width * 0.5)
        color: Theme.fgIslandDim
    }
}
