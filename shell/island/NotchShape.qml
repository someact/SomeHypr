import QtQuick
import QtQuick.Shapes
import qs.core

// The notch: a body hanging from the screen's top edge, with concave "ears"
// that blend it into the edge and convex bottom corners.
//
//   (0,0)________________________________(W,0)
//        \ ear                      ear /
//         |                            |
//         |           body             |
//          \__________________________/
//
// The item is `ear` wider than the body on each side. With `floating` there are
// no ears: the body is a free-standing rounded pill (floating/satellites styles).
Shape {
    id: root

    property real bodyWidth: 200
    property real bodyHeight: 32
    property real ear: 12
    property real radius: 16
    property color color: Theme.island
    property bool floating: false

    readonly property real r: floating ? Math.max(0, Math.min(radius, bodyHeight / 2, bodyWidth / 2)) : Math.max(0, Math.min(radius, bodyHeight - ear, bodyWidth / 2))

    width: bodyWidth + ear * 2
    height: bodyHeight
    preferredRendererType: Shape.CurveRenderer

    // Notch: ears into the screen edge, rounded bottom
    ShapePath {
        fillColor: root.floating ? "transparent" : root.color
        strokeWidth: -1
        startX: 0
        startY: 0

        PathArc {
            x: root.ear
            y: root.ear
            radiusX: root.ear
            radiusY: root.ear
            direction: PathArc.Clockwise
        }
        PathLine {
            x: root.ear
            y: root.bodyHeight - root.r
        }
        PathArc {
            x: root.ear + root.r
            y: root.bodyHeight
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: root.width - root.ear - root.r
            y: root.bodyHeight
        }
        PathArc {
            x: root.width - root.ear
            y: root.bodyHeight - root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Counterclockwise
        }
        PathLine {
            x: root.width - root.ear
            y: root.ear
        }
        PathArc {
            x: root.width
            y: 0
            radiusX: root.ear
            radiusY: root.ear
            direction: PathArc.Clockwise
        }
        PathLine {
            x: 0
            y: 0
        }
    }

    // Floating: every corner rounded
    ShapePath {
        fillColor: root.floating ? root.color : "transparent"
        strokeWidth: -1
        startX: 0
        startY: root.r

        PathArc {
            x: root.r
            y: 0
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }
        PathLine {
            x: root.width - root.r
            y: 0
        }
        PathArc {
            x: root.width
            y: root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }
        PathLine {
            x: root.width
            y: root.bodyHeight - root.r
        }
        PathArc {
            x: root.width - root.r
            y: root.bodyHeight
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }
        PathLine {
            x: root.r
            y: root.bodyHeight
        }
        PathArc {
            x: 0
            y: root.bodyHeight - root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }
        PathLine {
            x: 0
            y: root.r
        }
    }
}
