import QtQuick
import Quickshell

Command {
    name: "ocr"
    icon: "document_scanner"
    description: "Copy text from a screen region"
    function run(arg) {
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; f=$(mktemp --suffix .png); grim -g \"$(slurp)\" \"$f\" && tesseract \"$f\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | paste -sd+) | wl-copy; rm -f \"$f\""]);
    }
}
