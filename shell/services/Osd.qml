pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Short-lived on-screen display (volume, brightness, layout) shown in the island.
Singleton {
    id: root

    property string kind        // volume | mic | brightness | layout
    property string icon
    property real value: -1     // 0..1, or -1 for text-only
    property string text
    property bool visible: false

    function show(kind, icon, value, text) {
        root.kind = kind;
        root.icon = icon;
        root.value = value ?? -1;
        root.text = text ?? "";
        root.visible = true;
        hide.restart();
    }

    Timer {
        id: hide
        interval: Config.island.osdMs
        onTriggered: root.visible = false
    }
}
