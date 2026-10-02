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
    readonly property string wallpaperState: stateDir + "/wallpaper.json"   // { path, phase }
    readonly property string videoFrame: stateDir + "/video-frame.jpg"     // matugen input for video wallpapers

    // matugen outputs (matugen/config.toml)
    readonly property string colors: stateDir + "/colors.json"

    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || home + "/.cache"
    readonly property string thumbs: cacheHome + "/somehypr/thumbs"
    readonly property string mpvSocket: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/somehypr-mpvpaper.sock"

    readonly property string hyprDir: configHome + "/hypr"
    readonly property string scripts: hyprDir + "/scripts"
    readonly property string wallpapers: home + "/Pictures/Wallpapers"
    readonly property string projects: "/mnt/ssd_backup/Projects"

    function url(path) {
        return path.startsWith("file://") ? path : "file://" + path;
    }
}
