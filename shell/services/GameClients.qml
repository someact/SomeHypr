pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Feeds gamemoded's clients to hypr/modes/gamemode.lua. `gdbus monitor` streams
// gamemoded's GameRegistered/GameUnregistered signals (with the PID), so this
// never polls; the full PID list goes to GameMode.set_clients() on every change
// and after a config reload. Started by shell.qml only (not the settings app).
Singleton {
    id: root

    property list<int> pids: []

    function send() {
        Quickshell.execDetached(["hyprctl", "eval", `GameMode.set_clients({${root.pids.join(",")}})`]);
    }
    function set(pid, on) {
        if (on === pids.includes(pid))
            return;
        pids = on ? [...pids, pid] : pids.filter(p => p !== pid);
        send();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.pids.length > 0)
                root.send();
        }
    }

    Process {
        id: monitor
        running: true
        // Dies with the shell even if it is killed
        command: ["setpriv", "--pdeathsig", "TERM", "gdbus", "monitor", "--session", "--dest", "com.feralinteractive.GameMode"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/GameMode\.Game(Registered|Unregistered) \((\d+),/);
                if (m)
                    root.set(parseInt(m[2]), m[1] === "Registered");
            }
        }
        onExited: restart.restart()
    }
    Timer {
        id: restart
        interval: 10000
        onTriggered: monitor.running = true
    }

    // Games already registered at start (never starts gamemoded itself)
    Process {
        running: true
        command: ["busctl", "--user", "--auto-start=no", "--json=short", "call", "com.feralinteractive.GameMode", "/com/feralinteractive/GameMode", "com.feralinteractive.GameMode", "ListGames"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.pids = JSON.parse(text).data[0].map(g => g[0]);
                } catch (e) {
                    root.pids = [];
                }
                root.send();   // also clears PIDs left from a previous shell
            }
        }
    }
}
