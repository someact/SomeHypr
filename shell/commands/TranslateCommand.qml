import QtQuick
import qs.core
import qs.services

Command {
    name: "translate"
    icon: "translate"
    args: "[text]"
    description: "Translate a screen region, or the text typed after it"
    keepOpen: true
    function run(arg) {
        if (arg.trim() === "") {
            Capture.start("translate");
            return;
        }
        Capture.sourceText = arg;
        Capture.translated = "";
        Capture.translate(arg);
        UiState.open("translate");
    }
}
