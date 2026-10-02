pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// cliphist history. Read only when the clipboard view opens; the wl-paste
// watchers in hypr/core/execs.lua do the storing.
Singleton {
    id: root

    property var entries: []    // { id, text, isImage }

    function refresh() {
        list.running = true;
    }
    function copy(entry) {
        Quickshell.execDetached(["bash", "-c", "printf '%s\\t%s' \"$1\" \"$2\" | cliphist decode | wl-copy", "_", entry.id, entry.text]);
    }
    function remove(entry) {
        Quickshell.execDetached(["bash", "-c", "printf '%s\\t%s' \"$1\" \"$2\" | cliphist delete", "_", entry.id, entry.text]);
        entries = entries.filter(e => e !== entry);
    }
    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const tab = l.indexOf("\t");
                    const body = l.slice(tab + 1);
                    return { id: l.slice(0, tab), text: body, isImage: body.startsWith("[[ binary data") };
                });
            }
        }
    }
}
