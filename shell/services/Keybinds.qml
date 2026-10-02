pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Described Hyprland binds for the /keys view. Read when the view opens.
Singleton {
    id: root

    property var binds: []   // { keys, group, action }

    function refresh() {
        proc.running = true;
    }

    readonly property var modNames: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = JSON.parse(text).filter(b => b.description && b.description !== "").map(b => {
                        const mods = root.modNames.filter(m => b.modmask & m[0]).map(m => m[1]);
                        const d = b.description.split(":");
                        return {
                            keys: mods.concat([b.key]).join(" + "),
                            group: d.length > 1 ? d[0].trim() : "",
                            action: (d.length > 1 ? d.slice(1).join(":") : d[0]).trim()
                        };
                    });
                } catch (e) {
                    console.warn("Keybinds: parse failed", e);
                }
            }
        }
    }
}
