pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

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
    function appIcon(appId) {
        const e = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(e?.icon ?? appId, "application-x-executable");
    }
}
