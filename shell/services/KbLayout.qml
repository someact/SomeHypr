pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Active keyboard layout (US/TH), from Hyprland's `activelayout` event.
Singleton {
    id: root

    property string layout: ""
    readonly property string code: {
        const l = layout.toLowerCase();
        if (l.includes("thai"))
            return "TH";
        if (l.includes("english"))
            return "US";
        return layout.slice(0, 2).toUpperCase();
    }

    function next() {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;
            const name = event.data.split(",").slice(1).join(",");
            if (name === root.layout || name === "")
                return;
            root.layout = name;
            Osd.show("layout", "keyboard", -1, root.code);
        }
    }

    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards;
                    root.layout = (kb.find(k => k.main) ?? kb[0])?.active_keymap ?? "";
                } catch (e) {}
            }
        }
    }
}
