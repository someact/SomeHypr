import QtQuick
import qs.core
import qs.components
import qs.services

// Synced lyrics of the playing track on the desktop: five lines, the current
// one centered. Shown while something plays; the line follows only while the
// desktop is visible.
DesktopWidget {
    id: root

    property bool live: true
    visible: Media.active || editing

    readonly property bool watching: live && Media.active && Config.media.lyrics
    property bool counted: false
    onWatchingChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: if (counted) Lyrics.watchers--
    function sync() {
        if (watching !== counted) {
            Lyrics.watchers += watching ? 1 : -1;
            counted = watching;
            Lyrics.sync();
        }
    }

    Column {
        width: 360
        spacing: 6
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Media.active ? Media.title + (Media.artist !== "" ? "  ·  " + Media.artist : "") : "Lyrics"
            color: root.fgDim
            font.pixelSize: Theme.font.small
        }
        LyricsPane {
            width: parent.width
            height: 170
            lines: Lyrics.lines
            index: Lyrics.index
            plain: Lyrics.plain
            synced: Lyrics.synced
            fg: root.fg
            fgDim: root.fgDim
            outline: !root.framed
            fontSize: Theme.font.large
            seekable: Media.player?.canSeek ?? false
            message: !Config.media.lyrics ? "Lyrics are off (Settings → Island)"
                : !Media.active ? "Nothing playing"
                : Lyrics.status === "loading" ? "Looking for lyrics…"
                : Lyrics.status === "none" ? "No lyrics for this track"
                : Lyrics.status === "error" ? "Couldn't reach lrclib.net"
                : Lyrics.has ? "" : "…"
            onSeek: time => {
                Media.player.position = time;
                Lyrics.sync();
            }
            onMessageClicked: Lyrics.retry()
        }
    }
}
