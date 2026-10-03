pragma Singleton

import QtQuick
import Quickshell
import qs.core

// The Control view's quick tiles. Each tile is one long-lived object whose
// properties bind to their own source, so a change (the recording timer, the
// Wi-Fi name) updates that one property; nothing is rebuilt. The view lists
// tiles by id and looks the object up, so its delegates live as long as it does.
//
// Which tiles show, and in what order: Config.control.tiles (ids). Every other
// tile is hidden and can be added back in the view's edit mode.
Singleton {
    id: root

    // Every tile, in the order hidden ones are offered
    readonly property list<string> ids: ["wifi", "bluetooth", "dnd", "game", "nightlight", "caffeine", "mic", "dark", "streamer", "record", "screenshot", "keyboard"]
    // Tiles without hardware (no Bluetooth adapter) are left out of both lists
    readonly property list<string> shown: Array.from(Config.control.tiles).filter(id => ids.includes(id) && byId[id].available)
    readonly property list<string> hidden: ids.filter(id => !shown.includes(id) && byId[id].available)

    function tile(id) {
        return byId[id] ?? null;
    }
    function show(id) {
        if (!shown.includes(id))
            Config.control.tiles = shown.concat([id]);
    }
    function hide(id) {
        Config.control.tiles = shown.filter(t => t !== id);
    }
    function setOrder(list) {
        Config.control.tiles = list;
    }

    // `detail`: the Control view's page for a right-click (wifi, bluetooth,
    // nightlight, audio); otherwise right-click opens `settings` in the settings app
    component Tile: QtObject {
        property string icon
        property string title
        property string subtitle
        property bool active: false
        property bool available: true
        property string detail
        property string settings
        property var run: () => {}
    }

    readonly property var byId: ({ wifi: wifi, bluetooth: bluetooth, dnd: dnd, game: game, nightlight: nightlight, caffeine: caffeine, mic: mic, dark: dark, streamer: streamer, record: record, screenshot: screenshot, keyboard: keyboard })

    property Tile wifi: Tile {
        icon: Network.icon
        title: Network.hasWifi ? "Wi-Fi" : "Network"
        subtitle: Network.name
        active: Network.hasWifi ? Network.wifiEnabled : Network.connected
        detail: "wifi"
        run: () => Network.hasWifi ? Network.toggleWifi() : UiState.controlDetail = "wifi"
    }
    property Tile bluetooth: Tile {
        icon: BluetoothState.icon
        title: "Bluetooth"
        subtitle: BluetoothState.name
        active: BluetoothState.enabled
        available: BluetoothState.available
        detail: "bluetooth"
        run: () => BluetoothState.toggle()
    }
    property Tile dnd: Tile {
        icon: "do_not_disturb_on"
        title: "Do not disturb"
        subtitle: Notifs.dnd ? "On" : "Off"
        active: Notifs.dnd
        settings: "modes"
        run: () => Notifs.toggleDnd()
    }
    property Tile game: Tile {
        icon: "sports_esports"
        title: "Game mode"
        subtitle: GameMode.active ? "On" : "Auto"
        active: GameMode.active
        settings: "modes"
        run: () => GameMode.toggle()
    }
    property Tile nightlight: Tile {
        icon: "nightlight"
        title: "Night light"
        subtitle: NightLight.active ? NightLight.temperature + " K" : "Off"
        active: NightLight.active
        detail: "nightlight"
        run: () => NightLight.toggle()
    }
    property Tile caffeine: Tile {
        icon: "coffee"
        title: "Keep awake"
        subtitle: UiState.caffeine ? "On" : "Off"
        active: UiState.caffeine
        settings: "desktop"
        run: () => UiState.caffeine = !UiState.caffeine
    }
    property Tile mic: Tile {
        icon: Audio.micIcon
        title: "Microphone"
        subtitle: Audio.micMuted ? "Muted" : "On"
        active: !Audio.micMuted
        detail: "audio"
        run: () => Audio.toggleMicMute()
    }
    property Tile dark: Tile {
        icon: Config.theme.mode === "dark" ? "dark_mode" : "light_mode"
        title: "Dark mode"
        subtitle: Config.theme.mode === "dark" ? "On" : "Off"
        active: Config.theme.mode === "dark"
        settings: "wallpaper"
        run: () => Wallpaper.toggleLightDark()
    }
    property Tile streamer: Tile {
        icon: "cast"
        title: "Streamer mode"
        subtitle: Streamer.active ? (Streamer.auto && !Config.streamer.enabled ? "On · sharing" : "On") : "Off"
        active: Streamer.active
        settings: "modes"
        run: () => Streamer.toggle()
    }
    property Tile record: Tile {
        icon: Recorder.active ? "stop_circle" : "screen_record"
        title: "Record"
        subtitle: Recorder.active ? Recorder.elapsedText : "Region"
        active: Recorder.active
        settings: "capture"
        run: () => Recorder.active ? Recorder.stop() : Capture.start("record")
    }
    property Tile screenshot: Tile {
        icon: "screenshot_region"
        title: "Screenshot"
        subtitle: "Region"
        settings: "capture"
        run: () => Capture.start("shot")
    }
    property Tile keyboard: Tile {
        icon: "keyboard"
        title: "Keyboard"
        subtitle: UiState.osk ? "On" : "Off"
        active: UiState.osk
        settings: "desktop"
        run: () => UiState.osk = !UiState.osk
    }
}
