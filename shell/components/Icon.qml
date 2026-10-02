import QtQuick
import qs.core

// Material Symbols glyph by ligature name, e.g. Icon { name: "volume_up" }
Text {
    property string name
    property real size: 20
    property real fill: 0

    text: name
    color: Theme.fgIsland
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    font.family: Theme.font.icon
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill, "opsz": Math.min(48, Math.max(20, size)) })

    Behavior on fill {
        NumberAnimation { duration: Motion.fast }
    }
}
