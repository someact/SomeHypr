import QtQuick
import qs.services

Command {
    name: "ocr"
    icon: "document_scanner"
    description: "Copy text from a screen region"
    function run(arg) {
        Capture.start("ocr");
    }
}
