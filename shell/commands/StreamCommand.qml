import QtQuick
import qs.services

Command {
    name: "stream"
    icon: "cast"
    description: "Toggle streamer mode (masked notifications, private peeks)"
    function run(arg) {
        Streamer.toggle();
    }
}
