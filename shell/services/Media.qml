pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

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
    readonly property string art: artFor(player)
    readonly property real length: player?.length ?? 0
    readonly property real progress: length > 0 ? Math.min(1, (player?.position ?? 0) / length) : 0

    // Views that show progress raise this; position updates only while > 0
    property int watchers: 0

    // Browsers often leave the art out (Plasma browser integration downloads it to a
    // temp file, and not always). Fall back to another player of the same process
    // (Brave's own MPRIS + the extension), then to the YouTube thumbnail of the URL.
    function pidOf(p) {
        return String(p?.metadata["kde:pid"] ?? ((p?.dbusName ?? "").match(/instance_?(\d+)/) ?? [])[1] ?? "");
    }
    function artFor(p) {
        if (!p)
            return "";
        if (p.trackArtUrl)
            return p.trackArtUrl;
        const pid = pidOf(p);
        const kin = pid === "" ? [] : players.filter(q => q !== p && pidOf(q) === pid);
        const art = kin.find(q => q.trackArtUrl)?.trackArtUrl;
        if (art)
            return art;
        for (const q of [p, ...kin]) {
            const id = ((q.metadata["xesam:url"] ?? "").match(/(?:youtube\.com\/watch\?.*?v=|youtu\.be\/)([\w-]{11})/) ?? [])[1];
            if (id)
                return "https://i.ytimg.com/vi/" + id + "/mqdefault.jpg";
        }
        return "";
    }

    // The player's own volume: its Pipewire stream when one matches (works for
    // every app, browsers included), else MPRIS Volume when the player has it.
    readonly property PwNode stream: streamFor(player)
    readonly property bool hasVolume: stream !== null || (player?.volumeSupported ?? false) && (player?.canControl ?? false)
    readonly property real volume: stream ? (stream.audio?.volume ?? 0) : player?.volume ?? 0
    readonly property bool muted: stream?.audio?.muted ?? false

    // MPRIS names its bus org.mpris.MediaPlayer2.<app>[.instance<pid>]; Pipewire
    // streams carry the process id and binary. Match the pid first, then the name.
    function streamFor(p) {
        if (!p)
            return null;
        const streams = Audio.streams;
        const bus = (p.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "").toLowerCase();
        const pid = (bus.match(/instance_?(\d+)/) ?? [])[1] ?? "";
        const names = [bus.split(".")[0], (p.desktopEntry ?? "").toLowerCase(), (p.identity ?? "").toLowerCase()].filter(n => n.length > 1);
        if (pid !== "") {
            const byPid = streams.find(s => s.properties["application.process.id"] === pid);
            if (byPid)
                return byPid;
        }
        const label = s => [s.properties["application.process.binary"], s.properties["application.name"], s.properties["application.id"]].map(v => (v ?? "").toLowerCase());
        return streams.find(s => label(s).some(l => l !== "" && names.some(n => l === n || l.includes(n) || n.includes(l)))) ?? null;
    }
    function setVolume(v) {
        v = Math.max(0, Math.min(1, v));
        if (stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = v;
        } else if (player?.volumeSupported)
            player.volume = v;
    }
    function toggleMute() {
        if (stream?.audio)
            stream.audio.muted = !stream.audio.muted;
        else if (player?.volumeSupported)
            player.volume = player.volume > 0 ? 0 : 1;
    }

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

    // Stream properties (and volume) are only filled in for bound nodes
    PwObjectTracker {
        objects: root.watchers > 0 ? Audio.streams : []
    }

    Timer {
        running: root.watchers > 0 && root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}
