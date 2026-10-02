import QtQuick
import Quickshell
import qs.services

Command {
    name: "wallpaper"
    icon: "wallpaper"
    args: "[random | path]"
    description: "Change wallpaper and colors"
    function run(arg) {
        if (arg === "random")
            Wallpaper.random();
        else if (arg !== "")
            Wallpaper.set(arg.replace(/^~/, Quickshell.env("HOME")));
        else
            Wallpaper.pick();
    }
    function suggest(arg) {
        return "random".startsWith(arg) ? [{ label: "random", value: "random" }] : [];
    }
}
