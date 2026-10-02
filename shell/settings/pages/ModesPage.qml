import QtQuick
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    title: "Modes"
    subtitle: "Game mode, the game overlay, streaming and quiet time."

    Section {
        title: "Game mode"
        note: "While on: no blur, shadows or animations, the video wallpaper pauses, the dock hides and the island shrinks to a dot. Games keep tearing and VRR. Games started with gamemoderun count too, windowed or not."
        SettingRow {
            icon: "sports_esports"
            title: "Turn on for fullscreen games"
            subtitle: "Steam games, gamescope, .exe and Minecraft windows (hypr/rules/gaming.lua)"
            changed: HyprSettings.isSet("gameModeAuto")
            onReset: HyprSettings.unset("gameModeAuto")
            Switch {
                checked: HyprSettings.get("gameModeAuto", true)
                onToggled: on => HyprSettings.set("gameModeAuto", on)
            }
        }
        SettingRow {
            icon: GameMode.active ? "toggle_on" : "toggle_off"
            title: GameMode.active ? "Game mode is on" : "Game mode is off"
            subtitle: "Force it on or off now; Automatic hands control back to the rule above"
            Row {
                spacing: 8
                SButton {
                    kind: "text"
                    text: "Automatic"
                    onClicked: GameMode.auto()
                }
                SButton {
                    kind: GameMode.active ? "tonal" : "filled"
                    text: GameMode.active ? "Turn off" : "Turn on"
                    onClicked: GameMode.toggle()
                }
            }
        }
    }

    Section {
        title: "Game overlay"
        note: "Super+G. Widgets drag by their title; pinned ones stay on screen (click-through) after the overlay closes."
        SettingRow {
            icon: "point_scan"
            title: "Crosshair"
            subtitle: "Screen-center crosshair over everything; style it in the overlay"
            Switch {
                checked: Config.overlay.crosshair.enabled
                onToggled: on => Config.overlay.crosshair.enabled = on
            }
        }
        SettingRow {
            icon: "keep_off"
            title: "Pinned widgets"
            subtitle: Config.overlay.pinned.length > 0 ? Array.from(Config.overlay.pinned).join(", ") : "None"
            SButton {
                kind: "text"
                text: "Unpin all"
                enabled: Config.overlay.pinned.length > 0
                onClicked: Config.overlay.pinned = []
            }
        }
    }

    Section {
        title: "Streamer mode"
        note: "Notification text is hidden in the island, and peeks show on a layer that screen shares and recordings leave out."
        SettingRow {
            icon: "cast"
            title: "Streamer mode"
            subtitle: "Also /stream or the Control view"
            Switch {
                checked: Config.streamer.enabled
                onToggled: on => Config.streamer.enabled = on
            }
        }
        SettingRow {
            icon: "screen_share"
            title: "Turn on while sharing the screen"
            subtitle: "OBS, Discord and browser screen shares (Pipewire)"
            Switch {
                checked: Config.streamer.auto
                onToggled: on => Config.streamer.auto = on
            }
        }
        SettingRow {
            icon: "notifications_off"
            title: "Do not disturb while streaming"
            subtitle: "Only critical notifications peek"
            Switch {
                checked: Config.streamer.silence
                onToggled: on => Config.streamer.silence = on
            }
        }
    }

    Section {
        title: "Quiet"
        SettingRow {
            icon: "do_not_disturb_on"
            title: "Do not disturb"
            subtitle: "Notifications are kept in the list but never peek"
            Switch {
                checked: Config.notifications.dnd
                onToggled: on => Config.notifications.dnd = on
            }
        }
    }
}
