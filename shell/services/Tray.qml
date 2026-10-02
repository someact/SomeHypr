pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// StatusNotifier items (Steam, Discord, ...), passive ones hidden.
Singleton {
    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
}
