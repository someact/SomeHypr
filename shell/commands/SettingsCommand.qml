import QtQuick
import Quickshell
import qs.core

Command {
    name: "settings"
    icon: "settings"
    description: "Edit shell settings (settings app arrives in Phase 5)"
    function run(arg) {
        Quickshell.execDetached(["xdg-open", Paths.config]);
    }
}
