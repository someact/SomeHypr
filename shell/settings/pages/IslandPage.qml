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
        SettingRow {
            icon: "toolbar"
            title: "Style"
            subtitle: "Glass is a frosted pill. Floating shows only the icons and text, like a phone's status bar."
            Choice {
                model: [{ value: "glass", label: "Glass" }, { value: "floating", label: "Floating" }]
                value: Config.island.pillStyle
                onPicked: v => Config.island.pillStyle = v
            }
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
