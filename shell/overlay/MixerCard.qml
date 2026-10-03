import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.core
import qs.components
import qs.services

// Per-app volume: one slider per playback stream, plus the output itself.
OverlayCard {
    id: root
    icon: "graphic_eq"
    title: "Mixer"
    implicitWidth: 320

    readonly property var streams: Audio.streams

    PwObjectTracker {
        objects: root.streams
    }

    Column {
        width: parent.width
        spacing: 10

        Slider {
            width: parent.width
            height: 34
            icon: Audio.icon
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }

        Repeater {
            model: root.streams
            Column {
                id: stream
                required property PwNode modelData
                readonly property string app: Audio.appName(modelData)
                width: parent.width
                spacing: 4
                Label {
                    width: parent.width
                    text: stream.app + (stream.modelData.properties["media.name"] ? " · " + stream.modelData.properties["media.name"] : "")
                    color: Theme.fgIslandDim
                    font.pixelSize: Theme.font.small
                }
                Slider {
                    width: parent.width
                    height: 30
                    icon: stream.modelData.audio.muted ? "volume_off" : "volume_up"
                    value: stream.modelData.audio.volume
                    onMoved: v => {
                        stream.modelData.audio.muted = false;
                        stream.modelData.audio.volume = v;
                    }
                    onIconClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted
                }
            }
        }

        Label {
            visible: root.streams.length === 0
            text: "No apps playing"
            color: Theme.fgIslandDim
            font.pixelSize: Theme.font.small
        }
    }
}
