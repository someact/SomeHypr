import QtQuick
import qs.core

// Rounded translucent surface. The frost itself comes from the compositor:
// the owning window sets BackgroundEffect.blurRegion over this item.
Rectangle {
    radius: Theme.radius.full
    color: Theme.pill
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, Theme.glass ? 0.08 : 0.04)
}
