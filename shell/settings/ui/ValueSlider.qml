import QtQuick
import qs.core

// Thin Material slider with the value beside it. `moved(v)` fires while dragging
// (already stepped and clamped); `value` stays bound by the caller.
Item {
    id: s

    property real from: 0
    property real to: 1
    property real stepSize: 0.1
    property real value: 0
    property int decimals: stepSize < 1 ? (stepSize < 0.1 ? 2 : 1) : 0
    property string suffix: ""
    signal moved(real value)

    implicitWidth: 260
    implicitHeight: 32

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    function pick(x) {
        const raw = from + Math.max(0, Math.min(1, x / track.width)) * (to - from);
        const stepped = Math.round(raw / stepSize) * stepSize;
        s.moved(Number(Math.max(from, Math.min(to, stepped)).toFixed(6)));
    }

    Item {
        id: track
        width: parent.width - 56
        height: parent.height
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.surfaceHighest
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * s.frac
            height: 6
            radius: 3
            color: Theme.primary
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * s.frac - width / 2
            width: mouse.pressed ? 6 : 4
            height: 24
            radius: 2
            color: Theme.primary
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onPressed: event => s.pick(event.x - 6)
            onPositionChanged: event => {
                if (pressed)
                    s.pick(event.x - 6);
            }
            onWheel: event => s.moved(Math.max(s.from, Math.min(s.to, s.value + (event.angleDelta.y > 0 ? s.stepSize : -s.stepSize))))
        }
    }
    SText {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        horizontalAlignment: Text.AlignRight
        mono: true
        dim: true
        text: Number(s.value).toFixed(s.decimals) + s.suffix
    }
}
