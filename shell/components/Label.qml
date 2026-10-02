import QtQuick
import qs.core

// Text in the shell's type: Google Sans Flex at the body weight, digits always
// tabular (same width) so clocks, timers and percentages never jitter.
Text {
    property bool mono: false

    color: Theme.fgIsland
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    font.family: mono ? Theme.font.mono : Theme.font.ui
    font.pixelSize: Theme.font.normal
    font.weight: Theme.font.weight
    font.features: ({ "tnum": 1 })
}
