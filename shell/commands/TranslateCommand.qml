import QtQuick
import qs.core
import qs.services

Command {
    name: "translate"
    icon: "translate"
    args: "[text | live]"
    description: "Translate a screen region, the text typed after it, or (live) keep translating an area in the game overlay"
    keepOpen: true
    function run(arg) {
        if (arg.trim() === "live") {
            LiveTranslate.pick();
            return;
        }
        if (arg.trim() === "") {
            Capture.start("translate");
            return;
        }
        Capture.sourceText = arg;
        Capture.translated = "";
        Capture.translate(arg);
        UiState.open("translate");
    }
    function suggest(arg) {
        return "live".startsWith(arg.trim()) ? [{ label: "live · keep translating a screen area (game overlay)", value: "live" }] : [];
    }
}
