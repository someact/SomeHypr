import QtQuick
import qs.core

Command {
    name: "clip"
    icon: "content_paste"
    description: "Clipboard history"
    keepOpen: true
    function run(arg) {
        UiState.open("clipboard");
    }
}
