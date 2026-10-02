pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Desktop widgets: which exist, which are on (Config.widgets.enabled) and where
// they sit (Config.widgets.positions). widgets/DesktopWidgets.qml draws them.
Singleton {
    id: root

    readonly property var available: [
        { id: "clock", icon: "schedule", name: "Clock" },
        { id: "media", icon: "music_note", name: "Now playing" },
        { id: "system", icon: "monitoring", name: "System" },
        { id: "notes", icon: "sticky_note_2", name: "Notes" }
    ]
    // Game mode hides them all; edit mode shows the layer even with none on
    readonly property bool shown: !GameMode.active && (Config.widgets.enabled.length > 0 || UiState.widgetEdit)

    function isOn(id) {
        return Config.widgets.enabled.includes(id);
    }
    function toggle(id) {
        if (!available.some(w => w.id === id))
            return;
        const on = Config.widgets.enabled;
        Config.widgets.enabled = on.includes(id) ? on.filter(w => w !== id) : [...on, id];
    }
    function position(id) {
        return Config.widgets.positions?.[id] ?? null;
    }
    function setPosition(id, x, y) {
        const p = Object.assign({}, Config.widgets.positions ?? {});
        p[id] = { x: Math.round(x), y: Math.round(y) };
        Config.widgets.positions = p;
    }
    function resetPositions() {
        Config.widgets.positions = {};
    }
}
