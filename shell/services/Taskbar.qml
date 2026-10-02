pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core

// Dock contents: pinned apps (Config.dock.pinned) then running ones, keyed by
// lowercase app id. `apps` is a list of plain strings, so a ScriptModel over it
// keeps every delegate alive as windows come and go; each delegate looks its
// windows up in `windows`.
Singleton {
    id: root

    readonly property list<string> pinned: Array.from(Config.dock.pinned).map(id => id.toLowerCase())

    // key -> [Toplevel]
    readonly property var windows: {
        const map = {};
        for (const t of ToplevelManager.toplevels.values) {
            const key = t.appId.toLowerCase();
            if (key === "")
                continue;
            (map[key] = map[key] ?? []).push(t);
        }
        return map;
    }

    readonly property list<string> running: Object.keys(windows).filter(k => !pinned.includes(k))
    readonly property list<string> apps: pinned.concat(running)

    // Last focused window per app, so clicking an app returns to where you were
    property var lastActive: ({})
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            const t = ToplevelManager.activeToplevel;
            if (t && t.appId !== "")
                root.lastActive[t.appId.toLowerCase()] = t;
        }
    }

    function windowsOf(key) {
        return windows[key] ?? [];
    }
    function isActive(key) {
        return windowsOf(key).some(t => t.activated);
    }
    function entry(key) {
        return DesktopEntries.heuristicLookup(key);
    }
    function name(key) {
        return entry(key)?.name ?? key;
    }

    // Focus the app: its last used window, or the next one if it is already focused
    function activate(key) {
        const list = windowsOf(key);
        if (list.length === 0) {
            launch(key);
            return;
        }
        const current = list.findIndex(t => t.activated);
        if (current >= 0) {
            list[(current + 1) % list.length].activate();
            return;
        }
        const last = lastActive[key];
        (list.includes(last) ? last : list[0]).activate();
    }
    function cycle(key, delta) {
        const list = windowsOf(key);
        if (list.length === 0)
            return;
        const current = Math.max(0, list.findIndex(t => t.activated));
        list[(current + delta + list.length) % list.length].activate();
    }
    function launch(key) {
        const e = entry(key);
        if (e)
            Apps.launch(e);
        else
            Quickshell.execDetached([key]);
    }
    function closeAll(key) {
        for (const t of windowsOf(key))
            t.close();
    }

    function isPinned(key) {
        return pinned.includes(key);
    }
    // index: position among pinned apps; past the end appends
    function pin(key, index) {
        const list = pinned.filter(k => k !== key);
        list.splice(index ?? list.length, 0, key);
        Config.dock.pinned = list;
    }
    function unpin(key) {
        Config.dock.pinned = pinned.filter(k => k !== key);
    }
    function togglePin(key) {
        if (isPinned(key))
            unpin(key);
        else
            pin(key);
    }
}
