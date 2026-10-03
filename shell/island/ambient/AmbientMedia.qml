import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import qs.core
import qs.components
import qs.services

// Now playing: cover with a progress ring, title (or the current lyric line,
// media.ambientLyrics), live peak bars.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    // Lyrics is only touched (and created) when the option is on
    readonly property bool lyricMode: Config.media.lyrics && Config.media.ambientLyrics && Lyrics.synced
    readonly property string text: lyricMode && Lyrics.line !== "" ? Lyrics.line
        : Media.artist !== "" ? Media.title + "  ·  " + Media.artist : Media.title

    readonly property bool wantLyrics: Config.media.lyrics && Config.media.ambientLyrics
    property bool following: false
    function syncWatch() {
        if (wantLyrics !== following) {
            Lyrics.watchers += wantLyrics ? 1 : -1;
            following = wantLyrics;
            Lyrics.sync();
        }
    }
    onWantLyricsChanged: syncWatch()
    Component.onCompleted: {
        Media.watchers++;
        syncWatch();
    }
    Component.onDestruction: {
        Media.watchers--;
        if (following)
            Lyrics.watchers--;
    }

    // A new line fades out the old one, swaps the text, fades back in
    onTextChanged: swap.restart()
    SequentialAnimation {
        id: swap
        NumberAnimation { target: title; property: "opacity"; to: 0; duration: Motion.fast }
        ScriptAction { script: title.text = root.text }   // PropertyAction would keep the value from restart()
        NumberAnimation { target: title; property: "opacity"; to: 1; duration: Motion.normal }
    }

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
                    strokeColor: Theme.accentIsland
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
            id: title
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.lyricMode ? 320 : 220)
            Component.onCompleted: text = root.text
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
                color: Theme.accentIsland
                Behavior on height {
                    Spring { preset: "snappy" }
                }
            }
        }
    }
}
