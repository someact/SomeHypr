import QtQuick
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    title: "Modes"
    subtitle: "Game mode and quiet time."

    Section {
        title: "Game mode"
        note: "While on: no blur, shadows or animations, the video wallpaper pauses and the island shrinks to a dot. Games keep tearing and VRR."
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
