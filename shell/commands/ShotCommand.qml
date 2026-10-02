import QtQuick
import Quickshell

Command {
    name: "shot"
    icon: "screenshot_region"
    description: "Screenshot a region to the clipboard"
    function run(arg) {
        // Wait for the island to collapse so it is not in the shot
        Quickshell.execDetached(["sh", "-c", "pidof slurp || { sleep 0.3; hyprshot --freeze --clipboard-only --mode region --silent; }"]);
    }
}
