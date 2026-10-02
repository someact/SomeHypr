import QtQuick
import qs.services

Command {
    name: "record"
    icon: "screen_record"
    args: "[screen] [sound]"
    description: "Record a region or the screen (run again to stop)"
    function run(arg) {
        const words = arg.split(/\s+/);
        const sound = words.includes("sound");
        if (Recorder.active)
            Recorder.stop();
        else if (words.includes("screen"))
            Recorder.start("", sound);
        else
            Capture.start(sound ? "recordSound" : "record");
    }
    function suggest(arg) {
        return [
            { label: "region", value: "" },
            { label: "region with sound", value: "sound" },
            { label: "screen", value: "screen" },
            { label: "screen with sound", value: "screen sound" }
        ].filter(s => s.label.startsWith(arg) || s.value.startsWith(arg));
    }
}
