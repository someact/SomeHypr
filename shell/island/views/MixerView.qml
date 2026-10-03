import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.core
import qs.components
import qs.services

// Mixer (right-click the volume slider or the volume pill icon): the output,
// one slider per app playing (Audio.streams), the microphone, and the output
// and input pickers. ↑/↓ select a slider, ←/→ adjust, M mutes it.
FocusScope {
    id: root

    implicitWidth: 560
    implicitHeight: col.implicitHeight

    property int selected: -1
    // In screen order; follows apps coming and going (apps.children)
    readonly property var sliders: [output].concat(Array.from(apps.children).filter(c => c.slider).map(c => c.slider)).concat([input])

    PwObjectTracker {
        objects: Audio.streams
    }

    function handleKey(event) {
        const k = event.key;
        const n = sliders.length;
        if (k === Qt.Key_Down || k === Qt.Key_Up) {
            selected = selected < 0 ? 0 : (selected + (k === Qt.Key_Down ? 1 : -1) + n) % n;
            return true;
        }
        const s = sliders[selected];
        if (s && (k === Qt.Key_Left || k === Qt.Key_Right)) {
            s.set(s.value + (k === Qt.Key_Right ? 0.05 : -0.05));
            return true;
        }
        if (s && k === Qt.Key_M) {
            s.iconClicked();
            return true;
        }
        return UiState.navKey(event);
    }

    component Heading: Label {
        x: 4
        height: 22
        color: Theme.fgIslandDim
        font.pixelSize: Theme.font.small
    }

    Column {
        id: col
        width: parent.width
        spacing: 8

        Heading {
            text: "Output · " + Audio.deviceName(Audio.sink)
            width: parent.width - 8
        }
        Slider {
            id: output
            width: parent.width
            icon: Audio.icon
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
            trackColor: root.sliders[root.selected] === output ? Theme.islandRaisedHover : Theme.islandRaised
        }

        Heading {
            text: Audio.streams.length > 0 ? "Apps" : "Apps · nothing playing"
        }
        Column {
            id: apps
            width: parent.width
            spacing: 8

            Repeater {
                model: Audio.streams
                Row {
                    id: stream
                    required property PwNode modelData
                    readonly property alias slider: appSlider
                    readonly property string iconName: modelData.properties["application.icon-name"] || Audio.appName(modelData).toLowerCase()
                    readonly property string media: modelData.properties["media.name"] ?? ""
                    width: apps.width
                    spacing: 10

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        source: Quickshell.iconPath(stream.iconName, "audio-x-generic")
                    }
                    Column {
                        width: parent.width - 38
                        spacing: 4
                        Label {
                            width: parent.width
                            text: Audio.appName(stream.modelData) + (stream.media !== "" ? "  ·  " + stream.media : "")
                            font.pixelSize: Theme.font.small
                            color: Theme.fgIslandDim
                        }
                        Slider {
                            id: appSlider
                            width: parent.width
                            height: 32
                            icon: stream.modelData.audio.muted ? "volume_off" : "volume_up"
                            value: stream.modelData.audio.volume
                            onMoved: v => {
                                stream.modelData.audio.muted = false;
                                stream.modelData.audio.volume = v;
                            }
                            onIconClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted
                            trackColor: root.sliders[root.selected] === appSlider ? Theme.islandRaisedHover : Theme.islandRaised
                        }
                    }
                }
            }
        }

        Heading {
            text: "Input · " + Audio.deviceName(Audio.source)
            width: parent.width - 8
        }
        Slider {
            id: input
            width: parent.width
            icon: Audio.micIcon
            value: Audio.micVolume
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
            trackColor: root.sliders[root.selected] === input ? Theme.islandRaisedHover : Theme.islandRaised
        }

        AudioDevices {
            width: parent.width
        }
    }
}
