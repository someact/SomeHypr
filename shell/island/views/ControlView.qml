import QtQuick
import qs.core
import qs.components
import qs.services

// Quick toggles and sliders. ↑/↓ select, Enter toggles, ←/→ adjust a selected slider.
FocusScope {
    id: root

    implicitWidth: 560
    implicitHeight: col.implicitHeight

    // index into toggles, then sliders
    property int selected: -1
    readonly property var toggles: [
        { icon: Network.icon, title: Network.hasWifi ? "Wi-Fi" : "Network", subtitle: Network.name, active: Network.hasWifi ? Network.wifiEnabled : Network.connected, run: () => Network.hasWifi ? Network.toggleWifi() : UiState.close() },
        { icon: BluetoothState.icon, title: "Bluetooth", subtitle: BluetoothState.name, active: BluetoothState.enabled, run: () => BluetoothState.toggle() },
        { icon: "do_not_disturb_on", title: "Do not disturb", subtitle: Notifs.dnd ? "On" : "Off", active: Notifs.dnd, run: () => Notifs.toggleDnd() },
        { icon: "sports_esports", title: "Game mode", subtitle: GameMode.active ? "On" : "Auto", active: GameMode.active, run: () => GameMode.toggle() },
        { icon: "nightlight", title: "Night light", subtitle: NightLight.active ? NightLight.temperature + " K" : "Off", active: NightLight.active, run: () => NightLight.toggle() },
        { icon: "coffee", title: "Keep awake", subtitle: UiState.caffeine ? "On" : "Off", active: UiState.caffeine, run: () => UiState.caffeine = !UiState.caffeine },
        { icon: Audio.micIcon, title: "Microphone", subtitle: Audio.micMuted ? "Muted" : "On", active: !Audio.micMuted, run: () => Audio.toggleMicMute() },
        { icon: Config.theme.mode === "dark" ? "dark_mode" : "light_mode", title: "Dark mode", subtitle: Config.theme.mode === "dark" ? "On" : "Off", active: Config.theme.mode === "dark", run: () => Wallpaper.toggleLightDark() },
        { icon: "cast", title: "Streamer mode", subtitle: Streamer.active ? (Streamer.auto && !Config.streamer.enabled ? "On · sharing" : "On") : "Off", active: Streamer.active, run: () => Streamer.toggle() },
        { icon: Recorder.active ? "stop_circle" : "screen_record", title: "Record", subtitle: Recorder.active ? Recorder.elapsedText : "Region", active: Recorder.active, run: () => Capture.start("record") }
    ]
    readonly property int sliderCount: Brightness.available ? 3 : 2
    readonly property int total: toggles.length + sliderCount

    function sliderAt(i) {
        return [volume, mic, brightness][i];
    }
    function handleKey(event) {
        const k = event.key;
        if (k === Qt.Key_Down || k === Qt.Key_Up) {
            selected = selected < 0 ? 0 : (selected + (k === Qt.Key_Down ? 1 : -1) + total) % total;
            return true;
        }
        if ((k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) && selected >= 0 && selected < toggles.length) {
            toggles[selected].run();
            return true;
        }
        if ((k === Qt.Key_Left || k === Qt.Key_Right) && selected >= toggles.length) {
            const s = sliderAt(selected - toggles.length);
            s.set(s.value + (k === Qt.Key_Right ? 0.05 : -0.05));
            return true;
        }
        return UiState.navKey(event);
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Grid {
            columns: 2
            spacing: 8
            width: parent.width
            Repeater {
                model: root.toggles
                Toggle {
                    required property var modelData
                    required property int index
                    width: (col.width - 8) / 2
                    icon: modelData.icon
                    title: modelData.title
                    subtitle: modelData.subtitle
                    active: modelData.active
                    highlighted: root.selected === index
                    onClicked: modelData.run()
                }
            }
        }

        Slider {
            id: volume
            width: parent.width
            icon: Audio.icon
            value: Audio.volume
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
            trackColor: root.selected === root.toggles.length ? Theme.islandRaisedHover : Theme.islandRaised
        }
        Slider {
            id: mic
            width: parent.width
            icon: Audio.micIcon
            value: Audio.micVolume
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
            trackColor: root.selected === root.toggles.length + 1 ? Theme.islandRaisedHover : Theme.islandRaised
        }
        Slider {
            id: brightness
            visible: Brightness.available
            width: parent.width
            icon: "light_mode"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
            trackColor: root.selected === root.toggles.length + 2 ? Theme.islandRaisedHover : Theme.islandRaised
        }
    }
}
