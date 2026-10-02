pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// hyprsunset on/off. State is read once at start and then tracked locally.
Singleton {
    id: root

    property bool active: false
    property int temperature: 4500

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
