import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.services
import qs.settings
import qs.settings.ui

Page {
    id: page
    title: "Dock"
    subtitle: "The bottom dock. Drag icons in the dock itself to reorder; drag one up out of it to unpin."

    readonly property var pinned: Array.from(Config.dock.pinned)

    function move(i, delta) {
        const list = pinned.slice();
        const [item] = list.splice(i, 1);
        list.splice(Math.max(0, Math.min(list.length, i + delta)), 0, item);
        Config.dock.pinned = list;
    }

    Section {
        title: "Dock"
        SettingRow {
            icon: "dock_to_bottom"
            title: "Show the dock"
            Switch {
                checked: Config.dock.enabled
                onToggled: on => Config.dock.enabled = on
            }
        }
        SettingRow {
            enabled: Config.dock.enabled
            icon: "visibility_off"
            title: "Hiding"
            subtitle: Config.dock.autohide === "intelli" ? "Hides while a window covers it; touch the bottom edge to bring it back" : Config.dock.autohide === "auto" ? "Only shows when you touch the bottom edge" : "Always shown; windows make room for it"
            Choice {
                model: [{ value: "intelli", label: "Smart" }, { value: "auto", label: "Always hide" }, { value: "never", label: "Never" }]
                value: Config.dock.autohide
                onPicked: v => Config.dock.autohide = v
            }
        }
        SettingRow {
            enabled: Config.dock.enabled
            icon: "photo_size_select_large"
            title: "Icon size"
            changed: Config.dock.iconSize !== 44
            onReset: Config.dock.iconSize = 44
            ValueSlider {
                from: 32
                to: 64
                stepSize: 2
                suffix: " px"
                value: Config.dock.iconSize
                onMoved: v => Config.dock.iconSize = v
            }
        }
    }

    Section {
        title: "Pinned apps"
        note: "Right-click a running app in the dock to pin it."
        Repeater {
            model: page.pinned
            SettingRow {
                id: appRow
                required property string modelData
                required property int index
                // Re-looked up once the desktop entries finish loading
                readonly property var entry: DesktopEntries.applications.values.length, DesktopEntries.heuristicLookup(modelData)
                iconSource: Apps.iconSource(entry?.icon || modelData)
                title: entry?.name ?? modelData
                subtitle: modelData
                Row {
                    spacing: 2
                    IconButton {
                        width: 32
                        height: 32
                        icon: "arrow_upward"
                        iconSize: 18
                        iconColor: Theme.fgSurfaceVariant
                        hoverColor: Theme.surfaceHigh
                        enabled: appRow.index > 0
                        onClicked: page.move(appRow.index, -1)
                    }
                    IconButton {
                        width: 32
                        height: 32
                        icon: "arrow_downward"
                        iconSize: 18
                        iconColor: Theme.fgSurfaceVariant
                        hoverColor: Theme.surfaceHigh
                        enabled: appRow.index < page.pinned.length - 1
                        onClicked: page.move(appRow.index, 1)
                    }
                    IconButton {
                        width: 32
                        height: 32
                        icon: "close"
                        iconSize: 18
                        iconColor: Theme.error
                        hoverColor: Theme.surfaceHigh
                        onClicked: Config.dock.pinned = page.pinned.filter(k => k !== appRow.modelData)
                    }
                }
            }
        }
        SText {
            visible: page.pinned.length === 0
            padding: 16
            text: "No pinned apps"
            dim: true
        }
    }
}
