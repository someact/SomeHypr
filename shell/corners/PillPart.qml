import QtQuick
import QtQuick.Effects
import qs.core
import qs.components

// One part of a corner pill: workspaces, app title, tray, status icons or clock.
// `style` is "glass" or "floating" (Config.pills.<part>). CornerWindow places the
// parts and draws one frosted pill behind each run of glass parts. A floating
// part has no background: white content with a halo (Config.pills.halo), a soft
// drop shadow (one MultiEffect layer) or a glyph outline (children apply
// `textStyle` / `halo`).
Item {
    id: root

    property string style: "glass"
    property bool shown: true
    default property alias content: row.data
    property alias spacing: row.spacing

    readonly property bool floating: style === "floating"
    readonly property color fg: floating ? "#ffffff" : Theme.fgSurface
    readonly property color fgDim: floating ? Qt.rgba(1, 1, 1, 0.6) : Theme.outline
    readonly property color line: floating ? Qt.rgba(1, 1, 1, 0.5) : Theme.outlineVariant
    readonly property bool outline: floating && Config.pills.halo === "outline"
    readonly property int textStyle: outline ? Text.Outline : Text.Normal
    readonly property color halo: Qt.rgba(0, 0, 0, 0.6)

    visible: shown
    implicitWidth: row.implicitWidth - row.leftPadding - row.rightPadding
    height: parent ? parent.height : Theme.barHeight - 6

    // The padding is room around the content that the shadow layer also renders:
    // a layer is cut at its item's bounds, which flattened shapes that reach the
    // edge (the active workspace) or overshoot it while springing
    Row {
        id: row
        x: -leftPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        padding: 3

        layer.enabled: root.floating && Config.pills.halo === "shadow"
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.9)
            shadowBlur: 0.35
            blurMax: 6
            shadowVerticalOffset: 1
            shadowHorizontalOffset: 0
        }
    }
}
