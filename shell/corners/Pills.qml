import QtQuick
import Quickshell
import qs.core

// The pill zones of one screen. A zone's window exists only while the layout
// (Config.pills.layout, edited in Settings → Island) puts something in it.
Scope {
    id: root

    required property ShellScreen modelData

    Zone { zone: "left" }
    Zone { zone: "islandLeft" }
    Zone { zone: "islandRight" }
    Zone { zone: "right" }

    component Zone: LazyLoader {
        id: loader
        required property string zone
        active: (Config.pills.layout[zone] ?? []).length > 0
        CornerWindow {
            modelData: root.modelData
            zone: loader.zone
        }
    }
}
