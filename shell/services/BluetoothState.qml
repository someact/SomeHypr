pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// BlueZ state over D-Bus (Quickshell.Bluetooth).
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string name: !enabled ? "Off" : connected.length === 1 ? connected[0].name : connected.length > 1 ? connected.length + " devices" : "On"
    readonly property string icon: !enabled ? "bluetooth_disabled" : connected.length > 0 ? "bluetooth_connected" : "bluetooth"

    function toggle() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
}
