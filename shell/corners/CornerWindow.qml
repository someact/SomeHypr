import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.components

// A top corner: a row of PillParts. Each run of neighboring glass parts sits
// in one frosted pill (thin dividers between its parts); floating parts have
// no background. The window is fixed-size so content changes never resize the
// surface; only the parts take input and only the glass runs get blurred.
PanelWindow {
    id: win

    required property ShellScreen modelData
    property bool left: true
    default property alias content: parts.data
    property alias bar: bar

    screen: modelData
    WlrLayershell.namespace: "somehypr:pill"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.left: left
    anchors.right: !left
    // Satellites: the window reaches the screen center so the pill can sit beside the island
    readonly property bool satellite: Config.island.style === "satellites"
    implicitWidth: satellite ? Math.floor(modelData.width / 2) : 640
    implicitHeight: Theme.barHeight + 8
    color: "transparent"

    readonly property int pad: 8          // inside a glass pill, at its ends
    readonly property int gap: 6          // between pills / floating parts

    // Layout of the visible parts: x of each part, the glass runs and the
    // dividers inside them, and the total width
    readonly property var geo: {
        const ps = parts.children.filter(c => c.floating !== undefined && c.visible && c.implicitWidth > 0);
        const xs = [], runs = [], seps = [];
        let x = 0, prev = null;
        for (const p of ps) {
            const glass = !p.floating;
            if (prev === null) {
                if (glass) {
                    runs.push({ x: 0 });
                    x = pad;
                }
            } else if (glass && !prev.floating) {
                seps.push(x + pad);
                x += pad * 2 + 1;
            } else {
                if (!prev.floating) {
                    x += pad;
                    runs[runs.length - 1].w = x - runs[runs.length - 1].x;
                }
                x += gap;
                if (glass) {
                    runs.push({ x: x });
                    x += pad;
                }
            }
            xs.push(x);
            x += p.implicitWidth;
            prev = p;
        }
        if (prev && !prev.floating) {
            x += pad;
            runs[runs.length - 1].w = x - runs[runs.length - 1].x;
        }
        return { parts: ps, xs: xs, runs: runs, seps: seps, width: x };
    }

    mask: Region {
        item: bar
    }
    Region {
        id: blurArea
        Region { item: run0.visible ? run0.frost : null; radius: run0.frostRadius }
        Region { item: run1.visible ? run1.frost : null; radius: run1.frostRadius }
    }
    // Only with a glass run on the surface: an empty region blurs the whole window
    BackgroundEffect.blurRegion: Theme.blur && win.geo.runs.length > 0 && bar.y + bar.height > 1 ? blurArea : null

    Item {
        id: bar
        x: win.satellite ? (win.left ? win.width - UiState.islandWidth / 2 - 6 - width : UiState.islandWidth / 2 + 6) : (win.left ? 6 : win.width - width - 6)
        y: UiState.hidden ? -height - 4 : 3
        height: Theme.barHeight - 6
        width: win.geo.width
        Behavior on width {
            Spring { preset: "snappy" }
        }
        Behavior on y {
            Spring { preset: "snappy" }
        }

        RunGlass {
            id: run0
            run: win.geo.runs[0] ?? null
        }
        RunGlass {
            id: run1
            run: win.geo.runs[1] ?? null
        }
        Repeater {
            model: win.geo.seps
            Rectangle {
                required property real modelData
                x: modelData
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 14
                color: Theme.outlineVariant
                Behavior on x {
                    Spring { preset: "snappy" }
                }
            }
        }

        // The parts; PillPart reads its x from xOf()
        Item {
            id: parts
            anchors.fill: parent
            function xOf(item) {
                const i = win.geo.parts.indexOf(item);
                return i >= 0 ? win.geo.xs[i] : 0;
            }
        }
    }

    component RunGlass: Glass {
        property var run: null
        visible: run !== null
        x: run?.x ?? 0
        width: run?.w ?? 0
        height: parent.height
        Behavior on x {
            Spring { preset: "snappy" }
        }
        Behavior on width {
            Spring { preset: "snappy" }
        }
    }
}
