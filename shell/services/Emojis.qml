pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import "../lib/fuzzysort.js" as Fuzzy

// Emoji list from the data section of hypr/scripts/fuzzel-emoji.sh (shared with
// the fuzzel fallback). Loaded the first time the emoji view opens.
Singleton {
    id: root

    property var prepared: []
    property bool loaded: false

    function load() {
        if (!loaded)
            file.path = Paths.scripts + "/fuzzel-emoji.sh";
    }
    function query(text, limit) {
        if (text.trim() === "")
            return prepared.slice(0, limit).map(p => p.line);
        return Fuzzy.go(text, prepared, { key: "target", limit: limit }).map(r => r.obj.line);
    }
    function copy(line) {
        Quickshell.execDetached(["wl-copy", line.split(" ")[0]]);
    }

    FileView {
        id: file
        onLoaded: {
            const lines = text().split("\n");
            const start = lines.indexOf("### DATA ###");
            root.prepared = lines.slice(start + 1).filter(l => l.trim() !== "").map(l => ({ line: l.trim(), target: Fuzzy.prepare(l.trim()) }));
            root.loaded = true;
        }
    }
}
