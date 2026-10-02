pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Material 3 colors from matugen plus design tokens. The colors file is watched,
// so a new wallpaper recolors the shell without a restart.
Singleton {
    id: root

    property var c: ({})
    function pick(name, fallback) {
        return c[name] ?? fallback;
    }

    // Colors (fallbacks are a neutral dark palette for first start)
    readonly property color primary: pick("primary", "#c6c0ff")
    readonly property color fgPrimary: pick("on_primary", "#2e2a60")
    readonly property color primaryContainer: pick("primary_container", "#454077")
    readonly property color fgPrimaryContainer: pick("on_primary_container", "#e4dfff")
    readonly property color secondaryContainer: pick("secondary_container", "#47455a")
    readonly property color fgSecondaryContainer: pick("on_secondary_container", "#e4dff9")
    readonly property color tertiary: pick("tertiary", "#eab8d0")
    readonly property color error: pick("error", "#ffb4ab")
    readonly property color surface: pick("surface", "#131318")
    readonly property color surfaceLow: pick("surface_container_low", "#1b1b21")
    readonly property color surfaceContainer: pick("surface_container", "#1f1f25")
    readonly property color surfaceHigh: pick("surface_container_high", "#2a292f")
    readonly property color surfaceHighest: pick("surface_container_highest", "#35343a")
    readonly property color fgSurface: pick("on_surface", "#e5e1e9")
    readonly property color fgSurfaceVariant: pick("on_surface_variant", "#c8c5d0")
    readonly property color outline: pick("outline", "#928f9a")
    readonly property color outlineVariant: pick("outline_variant", "#47464f")
    readonly property color shadow: pick("shadow", "#000000")

    // The island is always near-black so it reads as a hardware notch
    readonly property color island: islandBlur ? Qt.rgba(0, 0, 0, Config.glass.islandTint) : "#000000"
    readonly property color fgIsland: "#f4f2f8"
    readonly property color fgIslandDim: "#a8a6b0"
    readonly property color islandRaised: Qt.rgba(1, 1, 1, 0.08)
    readonly property color islandRaisedHover: Qt.rgba(1, 1, 1, 0.14)
    readonly property color pill: Qt.rgba(surface.r, surface.g, surface.b, blur ? glassAlpha : 0.92)

    // Glass: a tint over the compositor frost, a 1 px light rim and a soft top
    // highlight (components/Glass.qml). Without frost (glass off, game mode) the
    // tints turn nearly opaque so text stays readable over anything.
    readonly property bool glass: Config.island.glass
    readonly property bool blur: glass && !GameMode.active
    readonly property bool islandBlur: blur && Config.glass.island   // off: a solid black notch
    readonly property real glassAlpha: Config.glass.tint
    readonly property color glassRim: Qt.rgba(1, 1, 1, Config.glass.rim ? 0.14 : 0.05)
    readonly property color glassHighlight: Qt.rgba(1, 1, 1, Config.glass.rim ? 0.07 : 0)

    // Floating corner pills: no background, so text and icons get a dark halo
    readonly property bool pillsFloating: Config.island.pillStyle === "floating"
    readonly property color fgPill: pillsFloating ? "#ffffff" : fgSurface
    readonly property color fgPillDim: pillsFloating ? Qt.rgba(1, 1, 1, 0.6) : outline
    readonly property color pillHalo: Qt.rgba(0, 0, 0, 0.6)
    // Halo: a soft drop shadow (one MultiEffect per floating pill) or a glyph outline (free)
    readonly property bool pillShadow: pillsFloating && Config.pills.halo === "shadow"
    readonly property int pillTextStyle: pillsFloating && !pillShadow ? Text.Outline : Text.Normal

    // Tokens
    readonly property QtObject radius: QtObject {
        readonly property int small: 8
        readonly property int normal: 14
        readonly property int large: 22
        readonly property int island: 26
        readonly property int full: 999
    }
    readonly property QtObject space: QtObject {
        readonly property int xs: 4
        readonly property int s: 8
        readonly property int m: 12
        readonly property int l: 16
        readonly property int xl: 24
    }
    readonly property QtObject font: QtObject {
        readonly property string ui: "Google Sans Flex"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property string icon: "Material Symbols Rounded"
        // Google Sans Flex is variable: these weights land on its wght axis (ii's look)
        readonly property int weight: 450       // body text, a touch firmer than Regular on glass
        readonly property int weightTitle: 550  // titles and labels that were DemiBold
        readonly property int small: 11
        readonly property int normal: 13
        readonly property int large: 16
        readonly property int title: 20
        readonly property int display: 34
    }

    // Collapsed island and corner pill height; also Hyprland's reserved top zone
    readonly property int barHeight: 32

    FileView {
        path: Paths.colors
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.c = JSON.parse(text());
            } catch (e) {
                console.warn("Theme: bad colors file", e);
            }
        }
    }
}
