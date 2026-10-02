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
    readonly property alias glass: adapter.glass
    readonly property alias pills: adapter.pills
    readonly property alias motion: adapter.motion
    readonly property alias clock: adapter.clock
    readonly property alias search: adapter.search
    readonly property alias notifications: adapter.notifications
    readonly property alias theme: adapter.theme
    readonly property alias dock: adapter.dock
    readonly property alias overview: adapter.overview
    readonly property alias capture: adapter.capture
    readonly property alias overlay: adapter.overlay
    readonly property alias streamer: adapter.streamer
    readonly property alias lock: adapter.lock
    readonly property alias widgets: adapter.widgets
    readonly property alias osk: adapter.osk
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
                property string pillStyle: "glass"    // glass: frosted pills · floating: icons only, like a phone status bar
            }
            property JsonObject glass: JsonObject {
                property real tint: 0.4               // surface tint over the frost (pills, dock, cards)
                property real islandTint: 0.55        // the island's darker "hardware" tint
                property bool rim: true               // 1 px light rim and top highlight
                property bool island: true            // false: the island alone is solid black (no frost)
            }
            property JsonObject pills: JsonObject {
                property string halo: "shadow"        // floating text and icons: shadow (soft) | outline
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
            property JsonObject capture: JsonObject {
                property bool saveShots: false        // also save region shots (always copied)
                property string shotDir: ""           // empty: ~/Pictures/Screenshots
                property string recordDir: ""         // empty: ~/Videos
                property string encoder: "h264_nvenc" // wf-recorder -c (libx264 for CPU encoding)
                property string translateTo: "th"     // translate-shell target language
                property bool snapWindows: true       // click a window to select it
            }
            property JsonObject overlay: JsonObject {
                property list<string> open: ["resources", "mixer"]   // widgets shown while the overlay is up
                property list<string> pinned: []      // also shown (click-through) while it is closed
                property var positions: ({})          // widget id -> { x, y }
                property JsonObject crosshair: JsonObject {
                    property bool enabled: false
                    property string color: "#00ff88"
                    property int size: 10             // arm length
                    property int gap: 4
                    property int thickness: 2
                    property bool dot: true
                    property bool outline: true
                }
            }
            property JsonObject streamer: JsonObject {
                property bool enabled: false
                property bool auto: true              // on while the screen is shared (OBS, Discord, browser)
                property bool silence: true           // do not disturb while on (critical still peeks)
            }
            property JsonObject lock: JsonObject {
                property bool useHyprlock: false      // hand locking to hyprlock instead of the shell
                property bool blur: true              // blurred wallpaper behind the clock
                property bool showMedia: true         // now playing + controls
                property bool showNotifications: true // count of unread notifications (never their text)
            }
            property JsonObject widgets: JsonObject {
                // Desktop widgets on the bottom layer, in this order; hidden in game mode
                property list<string> enabled: ["clock", "media"]
                property var positions: ({})          // widget id -> { x, y }
                property bool glass: true             // frosted card behind each widget
            }
            property JsonObject osk: JsonObject {
                property bool pinned: false           // reserve space so windows sit above it
                property real scale: 1.0              // key size
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
