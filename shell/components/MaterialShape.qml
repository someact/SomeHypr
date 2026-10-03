import QtQuick
import QtQuick.Shapes
import qs.core
import "../lib/shapes/material-shapes.js" as MaterialShapes
import "../lib/shapes/morph-cache.js" as MorphCache

// A Material 3 Expressive shape (cookie, clover, pill, sunny, …), centered and
// fit into the item. Drawn with QtQuick.Shapes, so it is GPU curves with no
// offscreen Canvas texture per shape. Changing `shape` morphs the outline from
// the old one with a spring; the path is rebuilt only while that runs. Morphs
// and resting outlines are shared between all shapes (lib/shapes/morph-cache.js),
// so ten workspace shapes morphing together match each outline pair only once.
//
//   MaterialShape { shape: "cookie7Sided"; color: Theme.primary }
//
// Names are the getters in lib/shapes/material-shapes.js without "get" and
// with a lower-case first letter: circle, square, slanted, arch, fan, arrow,
// semiCircle, oval, pill, triangle, diamond, clamShell, pentagon, gem, sunny,
// verySunny, cookie4Sided, cookie6Sided, cookie7Sided, cookie9Sided,
// cookie12Sided, ghostish, clover4Leaf, clover8Leaf, burst, softBurst, boom,
// softBoom, flower, puffy, puffyDiamond, pixelCircle, pixelTriangle, bun, heart.
Shape {
    id: root

    property string shape: "circle"
    property color color: Theme.primary
    property color borderColor: "transparent"
    property real borderWidth: 0

    readonly property string _name: MaterialShapes["get" + shape.charAt(0).toUpperCase() + shape.slice(1)] ? shape : "circle"
    readonly property var polygon: {
        const getter = MaterialShapes["get" + _name.charAt(0).toUpperCase() + _name.slice(1)];
        if (_name !== shape)
            console.warn("MaterialShape: unknown shape", shape);
        return getter();
    }

    // Morph state: from the previous outline to the current one (none until the
    // shape first changes; at rest the cached outline is drawn)
    property var _from: null
    property string _fromName: ""
    property var _morph: null
    property real _progress: 1
    // A morph only runs between whole shapes, so a change mid-morph waits until
    // the running one is almost done (instead of snapping back to its start)
    property bool _pending: false
    onPolygonChanged: {
        if (morph.enabled && _progress < 0.97) {
            _pending = true;
            return;
        }
        _startMorph();
    }
    on_ProgressChanged: if (_pending && _progress >= 0.97) _startMorph()
    function _startMorph() {
        _pending = false;
        if (_from === polygon)
            return;
        _morph = MorphCache.morph(_fromName || _name, _from ?? polygon, _name, polygon);
        _from = polygon;
        _fromName = _name;
        morph.enabled = false;
        _progress = 0;
        morph.enabled = !Motion.reduced;
        _progress = 1;
    }
    Component.onCompleted: {
        _from = polygon;
        _fromName = _name;
    }
    Behavior on _progress {
        id: morph
        Spring { preset: "snappy" }
    }

    // Normalized cubics (0..1) scaled into the item as an SVG path
    readonly property string svg: {
        const size = Math.min(width, height);
        if (size <= 0)
            return "";
        const cubics = _morph && _progress < 1 ? _morph.asCubics(_progress) : MorphCache.rest(_name);
        if (cubics.length === 0)
            return "";
        const ox = (width - size) / 2, oy = (height - size) / 2;
        let d = `M ${(ox + cubics[0].anchor0X * size).toFixed(2)} ${(oy + cubics[0].anchor0Y * size).toFixed(2)}`;
        for (const c of cubics)
            d += ` C ${(ox + c.control0X * size).toFixed(2)} ${(oy + c.control0Y * size).toFixed(2)} ${(ox + c.control1X * size).toFixed(2)} ${(oy + c.control1Y * size).toFixed(2)} ${(ox + c.anchor1X * size).toFixed(2)} ${(oy + c.anchor1Y * size).toFixed(2)}`;
        return d + " Z";
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
        strokeWidth: root.borderWidth > 0 ? root.borderWidth : -1
        PathSvg {
            path: root.svg
        }
    }
}
