pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// NetworkManager state over D-Bus (Quickshell.Networking): no nmcli processes.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool connected: wired !== null || wifiNetwork !== null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool hasWifi: wifi !== null

    readonly property string name: wired ? "Ethernet" : wifiNetwork?.name ?? (wifiEnabled ? "Not connected" : "Wi-Fi off")
    readonly property string icon: {
        if (wired)
            return "lan";
        if (wifiNetwork) {
            const s = wifiNetwork.signalStrength;
            return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
        }
        return hasWifi && wifiEnabled ? "signal_wifi_statusbar_not_connected" : "signal_disconnected";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }
}
