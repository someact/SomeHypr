import QtQuick
import qs.core

Command {
    name: "keys"
    icon: "keyboard"
    description: "Keyboard shortcuts"
    keepOpen: true
    function run(arg) {
        UiState.open("keys");
    }
}
