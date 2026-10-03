import QtQuick
import qs.core

// Enter motion for freshly loaded content (island views, ambient states,
// Control detail pages, settings pages): fades in and grows from `fromScale`,
// a beat after the container starts moving.
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
        // Not a SpringAnimation: inside an animation group Qt's SpringAnimation
        // segfaults on start (QQuickSpringAnimation::transition), it only works
        // in a Behavior or as `SpringAnimation on <property>`
        NumberAnimation {
            target: root.target
            property: "scale"
            to: 1
            duration: Motion.normal
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }
}
