import QtQuick
import qs.services

Command {
    name: "dnd"
    icon: "do_not_disturb_on"
    description: "Toggle do not disturb"
    function run(arg) {
        Notifs.toggleDnd();
    }
}
