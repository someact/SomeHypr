import QtQuick
import Quickshell
import qs.core
import qs.services

Command {
    name: "wallpaper"
    icon: "wallpaper"
    args: "[random | dark | light | path]"
    description: "Pick a wallpaper (image or video); colors follow"
    keepOpen: true
    function run(arg) {
        if (arg === "random")
            Wallpaper.random();
        else if (arg === "dark" || arg === "light")
            Wallpaper.setMode(arg);
        else if (arg !== "")
            Wallpaper.set(arg.replace(/^~/, Quickshell.env("HOME")));
        else
            return UiState.open("wallpaper");
        UiState.close();
    }
    function suggest(arg) {
        return ["random", "dark", "light"].filter(s => s.startsWith(arg)).map(s => ({ label: s, value: s }));
    }
}
