.pragma library

.import "shapes/morph.js" as Morph
.import "material-shapes.js" as MaterialShapes

// Morphs between Material shapes, built once per (from, to) pair and shared by
// every MaterialShape. Matching two outlines is the expensive part of a morph;
// the shapes themselves are already singletons (material-shapes.js getters).

var _morphs = {}
var _rest = {}

function morph(fromName, fromPolygon, toName, toPolygon) {
    const key = fromName + ">" + toName;
    let m = _morphs[key];
    if (!m) {
        m = new Morph.Morph(fromPolygon, toPolygon);
        _morphs[key] = m;
    }
    return m;
}

// The outline of a shape at rest, as cubics (read-only: shared). `name` must be
// a valid shape name (MaterialShape._name)
function rest(name) {
    let c = _rest[name];
    if (!c) {
        const polygon = MaterialShapes["get" + name.charAt(0).toUpperCase() + name.slice(1)]();
        c = morph(name, polygon, name, polygon).asCubics(1);
        _rest[name] = c;
    }
    return c;
}
