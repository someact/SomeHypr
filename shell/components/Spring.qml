import QtQuick
import qs.core

// SpringAnimation with a named preset from core/Motion.qml. Use inside a Behavior:
//   Behavior on width { Spring { preset: "snappy" } }
SpringAnimation {
    property string preset: "smooth"
    readonly property var params: Motion.get(preset)
    spring: params.spring
    damping: params.damping
    mass: params.mass
    epsilon: 0.05
}
