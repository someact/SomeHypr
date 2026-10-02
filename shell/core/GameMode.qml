pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Bridge to hypr/modes/gamemode.lua. Hyprland emits `custom>>somehypr_gamemode,<0|1>`
// whenever game mode flips, so this never polls; the state is read once at start.
// gamemoded clients reach Hyprland through services/GameClients.qml.
Singleton {
    id: root

    property bool active: false

    function toggle() {
        Quickshell.execDetached(["hyprctl", "eval", "GameMode.toggle()"]);
    }
    function auto() {
        Quickshell.execDetached(["hyprctl", "eval", "GameMode.auto()"]);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "custom" && event.data.startsWith("somehypr_gamemode,"))
                root.active = event.data.endsWith(",1");
        }
    }

    Process {
        running: true
        command: ["hyprctl", "repl", "return GameMode and GameMode.active"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "true"
        }
    }
}
