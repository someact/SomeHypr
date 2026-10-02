pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Current wallpaper (matugen writes its path) and the ways to change it.
// matugen recolors everything, including this shell, from the new image.
Singleton {
    id: root

    property string path: ""
    readonly property bool isVideo: /\.(mp4|webm|mkv|mov|gif)$/i.test(path)

    function set(file) {
        Quickshell.execDetached(["matugen", "image", file, "-m", Config.theme.mode]);
    }
    function random() {
        Quickshell.execDetached(["sh", "-c", 'f=$(find "$1" -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | shuf -n1); [ -n "$f" ] && matugen image "$f" -m "$2"', "_", Paths.wallpapers, Config.theme.mode]);
    }
    // Native file picker until the Phase 3 picker exists
    function pick() {
        Quickshell.execDetached(["sh", "-c", 'f=$(kdialog --getopenfilename "$1" "image/jpeg image/png image/webp") && [ -n "$f" ] && matugen image "$f" -m "$2"', "_", Paths.wallpapers, Config.theme.mode]);
    }
    function toggleLightDark() {
        Config.theme.mode = Config.theme.mode === "dark" ? "light" : "dark";
        if (path !== "" && !isVideo)
            set(path);
    }

    FileView {
        path: Paths.wallpaperPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.path = text().trim()
    }
}
