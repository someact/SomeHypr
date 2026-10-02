import QtQuick
import qs.core

Command {
    name: "overlay"
    icon: "stadia_controller"
    description: "Game overlay: crosshair, FPS limit, resources, mixer, notes"
    function run(arg) {
        UiState.overlay = true;
    }
}
