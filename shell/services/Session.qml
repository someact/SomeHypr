pragma Singleton

import QtQuick
import Quickshell

// Power and session actions.
Singleton {
    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }
    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
    function logout() {
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }
    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
    function firmware() {
        Quickshell.execDetached(["systemctl", "reboot", "--firmware-setup"]);
    }
}
