pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, stored in ~/.config/somehypr/config.json. Missing keys take the
// defaults below; edits from the shell write back to the file, and edits to the
// file reload live.
Singleton {
    id: root

    readonly property alias island: adapter.island
    readonly property alias motion: adapter.motion
    readonly property alias clock: adapter.clock
    readonly property alias search: adapter.search
    readonly property alias notifications: adapter.notifications
    readonly property alias theme: adapter.theme
    readonly property alias dock: adapter.dock
    readonly property alias overview: adapter.overview
    property bool ready: false

    FileView {
        path: Paths.config
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            // First run: write the defaults so the file is there to edit
            if (error === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", Paths.configDir]);
                writeAdapter();
            }
            root.ready = true;
        }

        JsonAdapter {
            id: adapter

            property JsonObject island: JsonObject {
                property string style: "notch"        // notch (floating, satellites: Phase 5)
                property bool glass: true             // compositor blur behind the island
                property int peekMs: 4000             // notification peek
                property int osdMs: 1500              // volume / brightness / layout
                property bool showMedia: true
            }
            property JsonObject motion: JsonObject {
                property real speed: 1.0              // scales every spring
                property bool reduce: false           // short fades instead of springs
            }
            property JsonObject clock: JsonObject {
                property string format: "HH:mm"
                property string dateFormat: "ddd d MMM"
            }
            property JsonObject search: JsonObject {
                property int maxResults: 8
            }
            property JsonObject notifications: JsonObject {
                property bool dnd: false
                property int keep: 50
            }
            property JsonObject dock: JsonObject {
                property bool enabled: true
                // intelli: hide while a window covers it · auto: show on hover only · never: always shown, reserves space
                property string autohide: "intelli"
                property int iconSize: 44
                property list<string> pinned: ["org.kde.dolphin", "kitty", "brave-origin", "antigravity"]
            }
            property JsonObject overview: JsonObject {
                property int rows: 2
                property int columns: 5
                property real scale: 0.17             // workspace tile size relative to the screen
                property bool showSpecial: true
            }
            property JsonObject theme: JsonObject {
                property string mode: "dark"          // dark | light (matugen -m)
                property string scheme: "scheme-tonal-spot"   // matugen -t
                // Day/night: switch wallpaper folder, mode and night light on a schedule
                property JsonObject schedule: JsonObject {
                    property bool enabled: false
                    property string dayStart: "07:00"
                    property string nightStart: "19:00"
                    property string dayFolder: ""     // empty: keep the current wallpaper
                    property string nightFolder: ""
                    property string dayMode: "light"
                    property string nightMode: "dark"
                    property bool nightLight: true
                }
            }
        }
    }
}
