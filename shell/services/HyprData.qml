pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core

// Workspaces and windows from Quickshell's native Hyprland IPC. It keeps itself
// up to date from socket2 events, so nothing here spawns hyprctl.
Singleton {
    id: root

    readonly property int groupSize: 10
    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int groupStart: Math.floor((activeId - 1) / groupSize) * groupSize + 1

    readonly property HyprlandToplevel activeWindow: Hyprland.activeToplevel
    readonly property string activeTitle: activeWindow?.title ?? ""
    readonly property string activeAppId: activeWindow?.wayland?.appId ?? ""

    readonly property list<HyprlandToplevel> windows: Hyprland.toplevels.values

    // Open special workspace per monitor name ("special:special"), from `activespecial`
    property var special: ({})

    // Window geometry (lastIpcObject.at/size) is only fetched while something
    // needs it: dock intellihide or the overview. It is one socket request,
    // debounced, and only on events that can move windows (never on titles).
    readonly property bool trackGeometry: UiState.overview || (Config.dock.enabled && Config.dock.autohide === "intelli")
    readonly property var geometryEvents: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2", "activewindowv2", "activespecialv2", "moveworkspacev2", "monitoraddedv2", "monitorremovedv2"]

    function refreshGeometry() {
        refresh.restart();
    }
    onTrackGeometryChanged: if (trackGeometry) Hyprland.refreshToplevels()

    Timer {
        id: refresh
        interval: 40
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                // "special:name,DP-1" while open, ",DP-1" when closed
                const comma = event.data.lastIndexOf(",");
                const s = Object.assign({}, root.special);
                s[event.data.slice(comma + 1)] = event.data.slice(0, comma);
                root.special = s;
            }
            if (root.trackGeometry && root.geometryEvents.includes(event.name))
                refresh.restart();
        }
    }

    function occupied(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        return ws ? ws.toplevels.values.length > 0 : false;
    }
    // id: a number, or a Hyprland selector string such as "r+1"
    function focusWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${typeof id === "number" ? id : JSON.stringify(id)} })`);
    }
    function focusWindow(t) {
        t?.wayland?.activate();
    }
    function toggleSpecial(name) {
        Hyprland.dispatch(`hl.dsp.workspace.toggle_special(${JSON.stringify(name ?? "special")})`);
    }
    // workspace: a number or "special:name"
    function moveWindow(t, workspace) {
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${JSON.stringify(workspace)}, follow = false, window = "address:0x${t.address}" })`);
    }
    function closeWindow(t) {
        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:0x${t.address}" })`);
    }
    function isSpecial(t) {
        return (t?.workspace?.name ?? "").startsWith("special:");
    }
    function appIcon(appId) {
        const e = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(e?.icon ?? appId, "application-x-executable");
    }
}
