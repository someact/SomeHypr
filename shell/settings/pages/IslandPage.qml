import QtQuick
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    title: "Island"
    subtitle: "What the island shows while collapsed, and for how long."

    Section {
        title: "Corner pills"
        note: "Each part is a frosted glass pill (glass parts side by side share one pill) or floats with no background, like a phone's status bar."
        PartRow {
            part: "workspaces"
            icon: "view_week"
            title: "Workspaces"
        }
        SettingRow {
            icon: "cookie"
            title: "Active workspace shape"
            Choice {
                model: [{ value: "cookie7Sided", label: "Cookie" }, { value: "clover4Leaf", label: "Clover" }, { value: "sunny", label: "Sunny" }, { value: "pill", label: "Pill" }, { value: "circle", label: "Circle" }]
                value: Config.pills.workspaceShape
                onPicked: v => Config.pills.workspaceShape = v
            }
        }
        SettingRow {
            icon: "check_box_outline_blank"
            title: "Show empty workspaces"
            subtitle: "Off shows only workspaces with windows and the one you are on (holding Super shows them all)"
            Switch {
                checked: Config.pills.showEmpty
                onToggled: on => Config.pills.showEmpty = on
            }
        }
        PartRow {
            part: "title"
            icon: "web_asset"
            title: "App title"
        }
        PartRow {
            part: "tray"
            icon: "apps"
            title: "System tray"
        }
        PartRow {
            part: "status"
            icon: "wifi"
            title: "Status icons"
            subtitle: "Keyboard layout, network, Bluetooth, volume"
        }
        PartRow {
            part: "clock"
            icon: "schedule"
            title: "Date and time"
        }
        SettingRow {
            icon: "shadow"
            title: "Floating text"
            subtitle: "How floating parts stay readable: a soft shadow, or a thin outline (lightest)"
            enabled: ["workspaces", "title", "tray", "status", "clock"].some(k => Config.pills[k] === "floating")
            Choice {
                model: [{ value: "shadow", label: "Shadow" }, { value: "outline", label: "Outline" }]
                value: Config.pills.halo
                onPicked: v => Config.pills.halo = v
            }
        }
    }

    component PartRow: SettingRow {
        id: partRow
        required property string part
        Choice {
            model: [{ value: "glass", label: "Glass" }, { value: "floating", label: "Floating" }]
            value: Config.pills[partRow.part] ?? "glass"
            onPicked: v => Config.pills[partRow.part] = v
        }
    }

    Section {
        title: "Collapsed"
        SettingRow {
            icon: "music_note"
            title: "Show media"
            subtitle: "Album art, title and peak bars while something plays"
            Switch {
                checked: Config.island.showMedia
                onToggled: on => Config.island.showMedia = on
            }
        }
        SettingRow {
            icon: "notifications"
            title: "Notification peek"
            subtitle: "How long a new notification shows in the island"
            changed: Config.island.peekMs !== 4000
            onReset: Config.island.peekMs = 4000
            ValueSlider {
                from: 1
                to: 10
                stepSize: 0.5
                suffix: " s"
                value: Config.island.peekMs / 1000
                onMoved: v => Config.island.peekMs = Math.round(v * 1000)
            }
        }
        SettingRow {
            icon: "volume_up"
            title: "Volume and brightness display"
            subtitle: "How long the OSD stays after a change"
            changed: Config.island.osdMs !== 1500
            onReset: Config.island.osdMs = 1500
            ValueSlider {
                from: 0.5
                to: 5
                stepSize: 0.25
                suffix: " s"
                value: Config.island.osdMs / 1000
                onMoved: v => Config.island.osdMs = Math.round(v * 1000)
            }
        }
    }

    Section {
        title: "Clock"
        note: "Qt date format: HH hours, mm minutes, ap am/pm, ddd weekday, d day, MMM month."
        SettingRow {
            icon: "schedule"
            title: "Time format"
            subtitle: Qt.formatTime(new Date(), Config.clock.format)
            Field {
                implicitWidth: 180
                mono: true
                text: Config.clock.format
                onCommitted: t => {
                    if (t.trim() !== "")
                        Config.clock.format = t.trim();
                }
            }
        }
        SettingRow {
            icon: "calendar_today"
            title: "Date format"
            subtitle: Qt.formatDate(new Date(), Config.clock.dateFormat)
            Field {
                implicitWidth: 180
                mono: true
                text: Config.clock.dateFormat
                onCommitted: t => {
                    if (t.trim() !== "")
                        Config.clock.dateFormat = t.trim();
                }
            }
        }
    }

    Section {
        title: "Search"
        SettingRow {
            icon: "search"
            title: "Results"
            subtitle: "How many results search lists at most"
            changed: Config.search.maxResults !== 8
            onReset: Config.search.maxResults = 8
            ValueSlider {
                from: 4
                to: 14
                stepSize: 1
                value: Config.search.maxResults
                onMoved: v => Config.search.maxResults = v
            }
        }
    }

    Section {
        title: "Notifications"
        SettingRow {
            icon: "history"
            title: "History"
            subtitle: "How many notifications to keep"
            changed: Config.notifications.keep !== 50
            onReset: Config.notifications.keep = 50
            ValueSlider {
                from: 10
                to: 200
                stepSize: 10
                value: Config.notifications.keep
                onMoved: v => Config.notifications.keep = v
            }
        }
    }
}
