pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// hyprsunset on/off and temperature. State is read once at start and then
// tracked locally; a temperature change while on goes over hyprsunset's IPC.
Singleton {
    id: root

    property bool active: false
    readonly property int temperature: Config.theme.nightLightTemp

    function setTemperature(k) {
        Config.theme.nightLightTemp = Math.round(Math.max(2500, Math.min(6500, k)) / 50) * 50;
        if (active)
            apply.restart();
    }
    // One IPC call per pause while a slider drags
    Timer {
        id: apply
        interval: 80
        onTriggered: Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(root.temperature)])
    }

    function toggle() {
        if (active)
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        else
            Quickshell.execDetached(["hyprsunset", "-t", String(temperature)]);
        active = !active;
    }

    Process {
        running: true
        command: ["pidof", "hyprsunset"]
        onExited: code => root.active = code === 0
    }
}
