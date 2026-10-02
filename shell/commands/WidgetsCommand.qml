import QtQuick
import qs.core
import qs.services

Command {
    name: "widgets"
    icon: "widgets"
    description: "Edit desktop widgets (or /widgets clock|media|system|notes to toggle one)"
    function run(arg) {
        if (arg !== "") {
            Widgets.toggle(arg.toLowerCase());
            return;
        }
        UiState.close();
        UiState.widgetEdit = true;
    }
}
