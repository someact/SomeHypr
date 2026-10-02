import QtQuick
import Quickshell
import qs.core

Command {
    name: "record"
    icon: "screen_record"
    args: "[sound]"
    description: "Record a region (run again to stop)"
    function run(arg) {
        const script = Paths.scripts + "/record.sh";
        Quickshell.execDetached(arg === "sound" ? [script, "--sound"] : [script]);
    }
}
