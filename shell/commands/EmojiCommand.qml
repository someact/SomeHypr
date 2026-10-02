import QtQuick
import qs.core

Command {
    name: "emoji"
    icon: "mood"
    description: "Pick an emoji"
    keepOpen: true
    function run(arg) {
        UiState.open("emoji");
    }
}
