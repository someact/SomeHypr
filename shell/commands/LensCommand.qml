import QtQuick
import qs.services

Command {
    name: "lens"
    icon: "image_search"
    description: "Search a screen region with Google Lens"
    function run(arg) {
        Capture.start("lens");
    }
}
