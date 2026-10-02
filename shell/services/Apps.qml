pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import "../lib/fuzzysort.js" as Fuzzy

// Desktop apps with fuzzy search ranked by frecency (how often and how recently
// each app was launched from the island).
Singleton {
    id: root

    readonly property list<DesktopEntry> list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    // Fuzzy targets are prepared once per app list change, not per keystroke
    readonly property var prepared: list.map(a => ({
        entry: a,
        name: Fuzzy.prepare(a.name),
        extra: Fuzzy.prepare([a.genericName, a.keywords.join(" "), a.id].join(" "))
    }))

    property var frecency: ({})   // id -> { count, last }

    function rank(id) {
        const f = frecency[id];
        if (!f)
            return 0;
        const hours = (Date.now() - f.last) / 3600000;
        const recency = hours < 1 ? 4 : hours < 24 ? 2 : hours < 168 ? 1 : 0.5;
        return f.count * recency;
    }

    function query(text, limit) {
        // Empty query: the most used apps, if any
        if (text.trim() === "")
            return list.filter(a => rank(a.id) > 0).sort((a, b) => rank(b.id) - rank(a.id)).slice(0, Math.min(limit, 5));
        return Fuzzy.go(text, prepared, { keys: ["name", "extra"], limit: limit * 3, threshold: 0.3 })
            .map(r => ({ entry: r.obj.entry, score: r.score + Math.min(0.3, rank(r.obj.entry.id) * 0.02) }))
            .sort((a, b) => b.score - a.score)
            .slice(0, limit)
            .map(r => r.entry);
    }

    function launch(entry) {
        entry.execute();
        const f = frecency[entry.id] ?? { count: 0, last: 0 };
        frecency[entry.id] = { count: f.count + 1, last: Date.now() };
        frecencyChanged();
        save.restart();
    }

    function icon(entry) {
        return Quickshell.iconPath(entry?.icon ?? "", "application-x-executable");
    }

    Timer {
        id: save
        interval: 2000
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", Paths.stateDir]);
            file.setText(JSON.stringify(root.frecency));
        }
    }

    FileView {
        id: file
        path: Paths.frecency
        printErrors: false
        onLoaded: {
            try {
                root.frecency = JSON.parse(text());
            } catch (e) {}
        }
    }
}
