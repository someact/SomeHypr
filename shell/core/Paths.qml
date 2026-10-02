pragma Singleton

import QtQuick
import Quickshell

// Every file the shell reads or writes, in one place.
Singleton {
    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"

    // User choices (settings app owns this from Phase 5)
    readonly property string configDir: configHome + "/somehypr"
    readonly property string config: configDir + "/config.json"

    // Machine state: frecency, notification history
    readonly property string stateDir: stateHome + "/somehypr"
    readonly property string frecency: stateDir + "/frecency.json"
    readonly property string notifications: stateDir + "/notifications.json"

    // matugen outputs (shared with ii until Phase 3 moves them)
    readonly property string generated: stateHome + "/quickshell/user/generated"
    readonly property string colors: generated + "/colors.json"
    readonly property string wallpaperPath: generated + "/wallpaper/path.txt"

    readonly property string hyprDir: configHome + "/hypr"
    readonly property string scripts: hyprDir + "/scripts"
    readonly property string wallpapers: home + "/Pictures/Wallpapers"
    readonly property string projects: "/mnt/ssd_backup/Projects"

    function url(path) {
        return path.startsWith("file://") ? path : "file://" + path;
    }
}
