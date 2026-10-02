import QtQuick
import qs.services

Command {
    name: "lock"
    icon: "lock"
    description: "Lock the screen"
    function run(arg) {
        Session.lock();
    }
}
