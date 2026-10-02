pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Described Hyprland binds for the /keys cheatsheet, in config order, one per
// combo + description. Read when the view opens (binds change only on reload).
Singleton {
    id: root

    property var binds: []   // { keys, group, action }

    function refresh() {
        proc.running = true;
    }

    readonly property var modNames: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]

    // Keycode binds (the Thai-layout digit row is code:10..19) shown as their US key
    function keyName(b) {
        if (b.key !== "")
            return b.key.length === 1 ? b.key.toUpperCase() : b.key;
        if (b.keycode >= 10 && b.keycode <= 19)
            return String((b.keycode - 9) % 10);
        return "code:" + b.keycode;
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const seen = new Set();
                    root.binds = JSON.parse(text).filter(b => b.description && b.submap === "").map(b => {
                        const mods = root.modNames.filter(m => b.modmask & m[0]).map(m => m[1]);
                        const d = b.description.split(":");
                        return {
                            keys: mods.concat([root.keyName(b)]).join(" + "),
                            group: d.length > 1 ? d[0].trim() : "Other",
                            action: (d.length > 1 ? d.slice(1).join(":") : d[0]).trim()
                        };
                    }).filter(b => {
                        const id = b.keys + "|" + b.action;
                        return !seen.has(id) && seen.add(id);
                    });
                } catch (e) {
                    console.warn("Keybinds: parse failed", e);
                }
            }
        }
    }
}
