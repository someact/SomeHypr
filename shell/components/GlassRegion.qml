import QtQuick
import Quickshell

// Blur region for a Glass item, inset 1 px. Wayland regions are whole-pixel
// rectangles, so their rounded corners are stair-stepped; kept inside the item
// the steps sit under its anti-aliased rim instead of showing past the edge.
// `target` must be a direct child of the window (its x/y are window coordinates).
Region {
    required property Item target
    property int inset: 1
    readonly property int _r: Math.round(Math.min(target.radius ?? 0, target.width / 2, target.height / 2))

    x: Math.ceil(target.x) + inset
    y: Math.ceil(target.y) + inset
    width: Math.max(0, Math.floor(target.width) - inset * 2)
    height: Math.max(0, Math.floor(target.height) - inset * 2)
    radius: Math.max(0, _r - inset)
}
