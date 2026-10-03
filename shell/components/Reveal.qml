import QtQuick
import qs.core

// Enter motion for freshly loaded content (island views, ambient states,
// Control detail pages, settings pages): fades in and grows from `fromScale`
// on a spring, a beat after the container starts moving.
//
//   Loader { onLoaded: reveal.play(); Reveal { id: reveal; target: loader.item } }
//
// Only a new target starts from hidden. Playing again on the same item carries
// on from where it is, so a replay mid-way never jumps back to zero.
SequentialAnimation {
    id: root

    property Item target
    property real fromScale: 0.96
    property int delay: Motion.reduced ? 0 : 60
    property Item _last: null
    readonly property var _spring: Motion.get("smooth")

    function play() {
        if (!target)
            return;
        if (target !== _last) {
            _last = target;
            target.opacity = 0;
            target.scale = fromScale;
        }
        restart();
    }

    PauseAnimation {
        duration: root.delay
    }
    ParallelAnimation {
        NumberAnimation {
            target: root.target
            property: "opacity"
            to: 1
            duration: Motion.normal
            easing.type: Easing.OutCubic
        }
        SpringAnimation {
            target: root.target
            property: "scale"
            to: 1
            spring: root._spring.spring
            damping: root._spring.damping
            mass: root._spring.mass
            epsilon: 0.002
        }
    }
}
