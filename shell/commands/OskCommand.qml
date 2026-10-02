import QtQuick
import qs.core

Command {
    name: "osk"
    icon: "keyboard"
    description: "On-screen keyboard"
    function run(arg) {
        UiState.close();
        UiState.osk = !UiState.osk;
    }
}
