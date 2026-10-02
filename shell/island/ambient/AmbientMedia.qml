import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import qs.core
import qs.components
import qs.services

// Now playing: cover with a progress ring, scrolling title, live peak bars.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Component.onCompleted: Media.watchers++
    Component.onDestruction: Media.watchers--

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Item {
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Cover {
                anchors.fill: parent
                anchors.margins: 3
                radius: width / 2
                source: Media.art
                fallbackIcon: "music_note"
            }
            // progress ring
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.primary
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: 11
                        centerY: 11
                        radiusX: 10
                        radiusY: 10
                        startAngle: -90
                        sweepAngle: 360 * Media.progress
                    }
                }
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 220)
            text: Media.artist !== "" ? Media.title + "  ·  " + Media.artist : Media.title
            font.pixelSize: Theme.font.normal
        }

        Peaks {
            anchors.verticalCenter: parent.verticalCenter
            playing: Media.isPlaying
        }
    }

    component Peaks: Row {
        id: peaks
        property bool playing
        spacing: 2
        height: 14

        PwNodePeakMonitor {
            id: monitor
            node: Audio.sink
            enabled: peaks.playing && !GameMode.active
        }

        Repeater {
            model: 4
            Rectangle {
                required property int index
                readonly property real level: {
                    const p = monitor.peaks;
                    const l = p.length > 0 ? p[0] : 0, r = p.length > 1 ? p[1] : l;
                    return [l * 0.7, l, r, r * 0.7][index];
                }
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                radius: 1.5
                height: 3 + 11 * Math.min(1, peaks.playing ? level * 1.4 : 0)
                color: Theme.primary
                Behavior on height {
                    Spring { preset: "snappy" }
                }
            }
        }
    }
}
