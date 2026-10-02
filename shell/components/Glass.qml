import QtQuick
import qs.core

// Frosted surface: a tint over the compositor blur, a 1 px light rim and a soft
// top highlight. The frost itself comes from the owning window's
// BackgroundEffect.blurRegion; the region should stay 1 px inside this item so
// its whole-pixel corners hide under the smooth rim. Use GlassRegion for a
// direct child of the window, or `Region { item: g.frost; radius: g.frostRadius }`.
Rectangle {
    id: root

    property color tint: Theme.pill
    property bool highlight: Config.glass.rim
    readonly property alias frost: frostArea
    readonly property int frostRadius: Math.max(0, Math.round(Math.min(radius, width / 2, height / 2)) - 1)

    radius: Theme.radius.full
    color: tint
    border.width: 1
    border.color: Theme.glassRim

    Item {
        id: frostArea
        anchors.fill: parent
        anchors.margins: 1
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.highlight
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.glassHighlight }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }
}
