import QtQuick
import qs.core

// Thick pill slider with the icon inside the track (phone control-center style).
// `value` is 0..1; `moved(v)` fires while dragging or scrolling.
Item {
    id: root

    property real value: 0
    property string icon
    property string label
    property color fillColor: Theme.fgIsland
    property color trackColor: Theme.islandRaised
    property real step: 0.05
    readonly property bool dragging: mouse.pressed

    signal moved(real value)
    signal iconClicked

    implicitWidth: 260
    implicitHeight: 40

    function set(v) {
        root.moved(Math.max(0, Math.min(1, v)));
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
        clip: true

        Rectangle {
            id: fillBar
            height: parent.height
            radius: height / 2
            color: root.fillColor
            width: Math.max(height, parent.width * Math.min(1, root.value))
            Behavior on width {
                enabled: !root.dragging
                Spring { preset: "snappy" }
            }
        }
    }

    Icon {
        id: iconItem
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 20
        fill: 1
        color: fillBar.width > 34 ? Theme.surface : Theme.fgIsland
    }

    Label {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        mono: true
        text: root.label !== "" ? root.label : Math.round(root.value * 100)
        color: fillBar.width > parent.width - 40 ? Theme.surface : Theme.fgIslandDim
        font.pixelSize: Theme.font.small
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function at(x) {
            root.set(x / width);
        }
        onPressed: event => {
            if (event.x < 40)
                return;
            at(event.x);
        }
        onClicked: event => {
            if (event.x < 40)
                root.iconClicked();
        }
        onPositionChanged: event => {
            if (pressed && event.x >= 0)
                at(event.x);
        }
        onWheel: event => root.set(root.value + (event.angleDelta.y > 0 ? root.step : -root.step))
    }
}
