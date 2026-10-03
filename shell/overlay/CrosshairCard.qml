import QtQuick
import qs.core
import qs.components

// Crosshair settings. The crosshair itself (Crosshair.qml) stays on screen
// while enabled, overlay open or not.
OverlayCard {
    id: root
    icon: "point_scan"
    title: "Crosshair"
    implicitWidth: 300

    readonly property var c: Config.overlay.crosshair
    readonly property var colors: ["#00ff88", "#ffffff", "#ff3b30", "#ffd60a", "#00e5ff", "#ff2dd4"]

    component Stepper: Item {
        id: st
        property string name
        property int value
        property int min: 0
        property int max: 40
        signal stepped(int v)
        width: parent.width
        height: 30
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: st.name
            color: Theme.fgIslandDim
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            IconButton {
                width: 28
                height: 28
                iconSize: 16
                icon: "remove"
                color: Theme.islandRaised
                enabled: st.value > st.min
                onClicked: st.stepped(st.value - 1)
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                horizontalAlignment: Text.AlignHCenter
                mono: true
                text: st.value
            }
            IconButton {
                width: 28
                height: 28
                iconSize: 16
                icon: "add"
                color: Theme.islandRaised
                enabled: st.value < st.max
                onClicked: st.stepped(st.value + 1)
            }
        }
    }

    Column {
        width: parent.width
        spacing: 6

        Row {
            spacing: 6
            Toggle {
                width: 132
                height: 40
                icon: "point_scan"
                title: root.c.enabled ? "On" : "Off"
                active: root.c.enabled
                activeColor: root.accent
                activeFg: root.onAccent
                onClicked: root.c.enabled = !root.c.enabled
            }
            Toggle {
                width: 132
                height: 40
                icon: "fiber_manual_record"
                title: "Dot"
                active: root.c.dot
                activeColor: root.accent
                activeFg: root.onAccent
                onClicked: root.c.dot = !root.c.dot
            }
        }
        Stepper {
            name: "Length"
            value: root.c.size
            onStepped: v => root.c.size = v
        }
        Stepper {
            name: "Gap"
            value: root.c.gap
            onStepped: v => root.c.gap = v
        }
        Stepper {
            name: "Thickness"
            value: root.c.thickness
            min: 1
            max: 8
            onStepped: v => root.c.thickness = v
        }
        Row {
            spacing: 8
            topPadding: 4
            Repeater {
                model: root.colors
                Rectangle {
                    required property string modelData
                    width: 26
                    height: 26
                    radius: 13
                    color: modelData
                    border.width: root.c.color === modelData ? 3 : 1
                    border.color: root.c.color === modelData ? Theme.fgIsland : Qt.rgba(0, 0, 0, 0.5)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.c.color = parent.modelData
                    }
                }
            }
            IconButton {
                width: 26
                height: 26
                iconSize: 16
                icon: root.c.outline ? "border_outer" : "border_clear"
                color: Theme.islandRaised
                onClicked: root.c.outline = !root.c.outline
            }
        }
    }
}
