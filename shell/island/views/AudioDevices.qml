import QtQuick
import Quickshell.Services.Pipewire
import qs.core
import qs.components
import qs.services

// Output and input pickers: every Pipewire device, the default one marked;
// click makes it the default (Pipewire.preferredDefaultAudio*). Used by the
// Control detail page and the mixer.
Column {
    id: root

    property bool showOutput: true
    property bool showInput: true

    spacing: 2

    PwObjectTracker {
        objects: Audio.sinks.concat(Audio.sources)
    }

    Section {
        visible: root.showOutput
        title: "Output"
    }
    Repeater {
        model: root.showOutput ? Audio.sinks : []
        DetailRow {
            required property PwNode modelData
            readonly property bool isDefault: modelData === Audio.sink
            icon: Audio.deviceIcon(modelData)
            title: Audio.deviceName(modelData)
            subtitle: isDefault ? "In use" + (modelData.audio?.muted ? " · muted" : "") : ""
            current: isDefault
            onClicked: Audio.setSink(modelData)
        }
    }

    Section {
        visible: root.showInput
        title: "Input"
    }
    Repeater {
        model: root.showInput ? Audio.sources : []
        DetailRow {
            required property PwNode modelData
            readonly property bool isDefault: modelData === Audio.source
            icon: Audio.deviceIcon(modelData)
            title: Audio.deviceName(modelData)
            subtitle: isDefault ? "In use" + (modelData.audio?.muted ? " · muted" : "") : ""
            current: isDefault
            onClicked: Audio.setSource(modelData)
        }
    }

    component Section: Label {
        property string title
        x: 12
        height: 28
        text: title
        color: Theme.fgIslandDim
        font.pixelSize: Theme.font.small
    }
}
