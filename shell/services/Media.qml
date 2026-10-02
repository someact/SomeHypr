pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The player worth showing: whichever is playing, else the one that played last.
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    readonly property var playing: players.filter(p => p.isPlaying)
    property MprisPlayer last: null
    onPlayingChanged: if (playing.length > 0) last = playing[0]

    readonly property MprisPlayer player: playing[0] ?? (players.includes(last) ? last : players[0] ?? null)
    readonly property bool active: player !== null && player.playbackState !== MprisPlaybackState.Stopped && (player.trackTitle ?? "") !== ""
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property real length: player?.length ?? 0
    readonly property real progress: length > 0 ? Math.min(1, (player?.position ?? 0) / length) : 0

    // Views that show progress raise this; position updates only while > 0
    property int watchers: 0

    function toggle() {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player?.canGoNext)
            player.next();
    }
    function previous() {
        if (player?.canGoPrevious)
            player.previous();
    }
    function seek(fraction) {
        if (player?.canSeek && length > 0)
            player.position = fraction * length;
    }

    Timer {
        running: root.watchers > 0 && root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
