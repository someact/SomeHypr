import QtQuick
import qs.services

Command {
    name: "shot"
    icon: "screenshot_region"
    description: "Screenshot a region (right-drag to annotate)"
    function run(arg) {
        Capture.start("shot");
    }
}
