pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink/source volume and mute, straight from Pipewire (no wpctl polling).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    // Devices and app streams (for the pickers and the mixer). Pipewire.nodes is
    // a live list; these filters only re-run when nodes come and go.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isSink && n.isStream)

    readonly property string icon: muted ? "volume_off" : volume <= 0.01 ? "volume_mute" : volume < 0.5 ? "volume_down" : "volume_up"
    readonly property string micIcon: micMuted ? "mic_off" : "mic"

    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
    function setMicVolume(v) {
        if (source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
    function setSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }
    function deviceName(node) {
        return node?.nickname || node?.description || node?.name || "";
    }
    function appName(stream) {
        return stream?.properties["application.name"] || stream?.description || stream?.name || "";
    }
    function deviceIcon(node) {
        const s = ((node?.properties["device.form-factor"] ?? "") + " " + (node?.properties["device.bus"] ?? "") + " " + (node?.name ?? "")).toLowerCase();
        if (s.includes("headset") || s.includes("headphone"))
            return "headphones";
        if (s.includes("bluez") || s.includes("bluetooth"))
            return "bluetooth";
        if (s.includes("hdmi") || s.includes("displayport"))
            return "tv";
        if (s.includes("usb"))
            return "usb";
        return node?.isSink ? "speaker" : "mic";
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // OSD on real changes only (not on startup or device switch)
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            Osd.show("volume", root.icon, root.volume);
        }
        function onMutedChanged() {
            Osd.show("volume", root.icon, root.muted ? 0 : root.volume);
        }
    }
    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() {
            Osd.show("mic", root.micIcon, -1, root.micMuted ? "Mic off" : "Mic on");
        }
    }
}
