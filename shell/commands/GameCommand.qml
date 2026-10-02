import QtQuick
import qs.core

Command {
    name: "game"
    icon: "sports_esports"
    description: "Toggle game mode (no blur, shadows or animations)"
    function run(arg) {
        GameMode.toggle();
    }
}
