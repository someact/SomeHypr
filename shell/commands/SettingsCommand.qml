import QtQuick
import Quickshell
import qs.core
import qs.services

Command {
    name: "settings"
    icon: "settings"
    description: "Open the settings app (optionally on a page: /settings keybinds)"
    function run(arg) {
        Session.openSettings(arg.trim().toLowerCase());
    }
}
