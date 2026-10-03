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
            visible: Config.overlay.style.look === "glass"
            icon: "blur_on"
            title: "Frosted glass"
            subtitle: "Blur the game behind the bar and cards while the overlay is open; off draws them solid"
            Switch {
                checked: Config.overlay.blur
                onToggled: on => Config.overlay.blur = on
            }
        }
        SettingRow {
            visible: Config.overlay.style.look === "glass"
            icon: "blur_circular"
            title: "Frost pinned widgets"
            subtitle: "Keep the blur behind pinned widgets after the overlay closes. In a game this keeps Hyprland's blur on (a small GPU cost, only under the cards); off draws them translucent"
            Switch {
                checked: Config.overlay.pinnedBlur
                onToggled: on => Config.overlay.pinnedBlur = on
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
        title: "Overlay style"
        note: "How the Super+G bar and widgets look. Applies live, also to pinned widgets."
        SettingRow {
            icon: "style"
            title: "Look"
            subtitle: "Glass: tinted and frosted · Solid: no blur · Minimal: no card when pinned, outlined text"
            Choice {
                value: Config.overlay.style.look
                model: [{ value: "glass", label: "Glass" }, { value: "solid", label: "Solid" }, { value: "minimal", label: "Minimal" }]
                onPicked: v => Config.overlay.style.look = v
            }
        }
        SettingRow {
            visible: Config.overlay.style.look !== "minimal"
            icon: "opacity"
            title: "Opacity"
            subtitle: "Darkness of the cards"
            changed: Config.overlay.style.opacity !== 0.5
            onReset: Config.overlay.style.opacity = 0.5
            ValueSlider {
                from: 0.2
                to: 0.95
                stepSize: 0.05
                value: Config.overlay.style.opacity
                onMoved: v => Config.overlay.style.opacity = v
            }
        }
        SettingRow {
            icon: "palette"
            title: "Accent"
            subtitle: "Icons and active buttons; Theme follows the wallpaper"
            Row {
                spacing: 8
                Repeater {
                    model: ["", "#00ff88", "#00e5ff", "#ffd60a", "#ff9f0a", "#ff3b30", "#ff2dd4", "#ffffff"]
                    Rectangle {
                        required property string modelData
                        width: 26
                        height: 26
                        radius: 13
                        color: modelData !== "" ? modelData : Theme.primary
                        border.width: Config.overlay.style.accent === modelData ? 3 : 1
                        border.color: Config.overlay.style.accent === modelData ? Theme.fgSurface : Qt.rgba(0, 0, 0, 0.4)
                        Icon {
                            anchors.centerIn: parent
                            visible: parent.modelData === ""
                            name: "wallpaper"
                            size: 14
                            color: Theme.fgPrimary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.overlay.style.accent = parent.modelData
                        }
                    }
                }
            }
        }
        SettingRow {
            icon: "rounded_corner"
            title: "Corner radius"
            changed: Config.overlay.style.radius !== 22
            onReset: Config.overlay.style.radius = 22
            ValueSlider {
                from: 0
                to: 32
                stepSize: 1
                suffix: " px"
                value: Config.overlay.style.radius
                onMoved: v => Config.overlay.style.radius = v
            }
        }
        SettingRow {
            icon: "density_small"
            title: "Compact"
            subtitle: "Slimmer title bars and padding"
            Switch {
                checked: Config.overlay.style.compact
                onToggled: on => Config.overlay.style.compact = on
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
