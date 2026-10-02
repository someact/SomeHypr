pragma Singleton

import QtQuick
import Quickshell

// What the island is showing. Every view, shortcut and IPC call goes through here.
Singleton {
    id: root

    // Views reachable with ←/→ while the island is open, in order
    readonly property list<string> mainViews: ["search", "control", "media", "notifications", "system", "power"]
    // Views opened by commands/shortcuts only
    readonly property list<string> extraViews: ["clipboard", "emoji", "keys", "polkit", "wallpaper"]

    property bool expanded: false
    property string view: "search"
    property string searchText: ""       // seed text for the search view, e.g. "/"
    property bool hidden: false          // Super+J hides the island and pills
    property bool caffeine: false        // block idle (screen off / lock)
    property string ambient: "clock"     // what the collapsed island shows (set by Island)
    property real islandWidth: 160       // live island width (satellite pills sit beside it)
    property bool overview: false        // Super+Tab workspace overview (never open together with the island)

    // Super tap: press arms it, any other key while held disarms it
    property bool superMightTrigger: false
    property bool superHeld: false

    signal searchReset

    function open(name, text) {
        if (!mainViews.includes(name) && !extraViews.includes(name)) {
            console.warn("UiState: unknown view", name);
            return;
        }
        view = name;
        if (name === "search") {
            searchText = text ?? "";
            searchReset();
        }
        overview = false;
        expanded = true;
    }

    function close() {
        expanded = false;
    }

    function toggle(name, text) {
        if (expanded && view === name)
            close();
        else
            open(name, text);
    }

    function toggleOverview() {
        overview = !overview;
        if (overview)
            close();
    }

    // Shared keys for views: Esc closes, ←/→ switch views
    function navKey(event) {
        if (event.key === Qt.Key_Escape) {
            close();
            return true;
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            step(event.key === Qt.Key_Left ? -1 : 1);
            return true;
        }
        return false;
    }

    function step(delta) {
        let i = mainViews.indexOf(view);
        if (i < 0)
            i = 0;
        view = mainViews[(i + delta + mainViews.length) % mainViews.length];
    }
}
