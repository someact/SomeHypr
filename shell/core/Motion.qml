pragma Singleton

import QtQuick
import Quickshell

// Spring presets. Springs keep their velocity when retargeted, so every
// animation can be interrupted mid-flight. Use them through components/Spring.qml.
// Matching Hyprland curves live in hypr/core/motion.lua.
Singleton {
    id: root

    // Game mode and the reduce-motion setting both collapse springs to short,
    // critically damped moves.
    readonly property bool reduced: Config.motion.reduce || GameMode.active
    readonly property real speed: Math.max(0.25, Config.motion.speed)

    readonly property var presets: ({
        smooth: { spring: 4.2, damping: 0.42, mass: 1.0 },
        snappy: { spring: 6.5, damping: 0.55, mass: 1.0 },
        bouncy: { spring: 5.0, damping: 0.26, mass: 1.0 },
        gentle: { spring: 2.6, damping: 0.45, mass: 1.0 },
        reduced: { spring: 30, damping: 1.0, mass: 1.0 }
    })

    function get(name) {
        const p = presets[reduced ? "reduced" : name] ?? presets.smooth;
        return { spring: p.spring * speed * speed, damping: p.damping, mass: p.mass };
    }

    // Fallback durations for things that cannot spring (colors)
    readonly property int fast: reduced ? 80 : Math.round(140 / speed)
    readonly property int normal: reduced ? 120 : Math.round(220 / speed)
}
