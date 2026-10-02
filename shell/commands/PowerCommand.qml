import QtQuick
import qs.core

Command {
    name: "power"
    icon: "power_settings_new"
    description: "Lock, suspend, log out, restart, shut down"
    keepOpen: true
    function run(arg) {
        UiState.open("power");
    }
}
