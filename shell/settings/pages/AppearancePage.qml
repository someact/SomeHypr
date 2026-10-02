import QtQuick
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    title: "Appearance"
    subtitle: "How the island looks, glass, motion and colors."

    Section {
        title: "Island"
        SettingRow {
            icon: "toast"
            title: "Style"
            subtitle: "Notch hangs from the top edge. Floating is a free pill. Satellites pulls the corner pills in beside it."
            Choice {
                model: [{ value: "notch", label: "Notch" }, { value: "floating", label: "Floating" }, { value: "satellites", label: "Satellites" }]
                value: Config.island.style
                onPicked: v => Config.island.style = v
            }
        }
        SettingRow {
            icon: "blur_on"
            title: "Glass"
            subtitle: "Frosted compositor blur behind the island, pills and dock"
            Switch {
                checked: Config.island.glass
                onToggled: on => Config.island.glass = on
            }
        }
    }

    Section {
        title: "Windows"
        note: "Applies on the next Hyprland reload, which happens right away."
        SettingRow {
            icon: "window"
            title: "Glass windows"
            subtitle: "Translucent terminals, chat and editors with stronger frost. Off keeps every window opaque."
            changed: HyprSettings.isSet("glass")
            onReset: HyprSettings.unset("glass")
            Switch {
                checked: HyprSettings.get("glass", false)
                onToggled: on => HyprSettings.set("glass", on)
            }
        }
    }

    Section {
        title: "Motion"
        SettingRow {
            icon: "speed"
            title: "Speed"
            subtitle: "Scales every spring in the shell"
            changed: Config.motion.speed !== 1
            onReset: Config.motion.speed = 1
            ValueSlider {
                from: 0.5
                to: 2
                stepSize: 0.1
                suffix: "×"
                value: Config.motion.speed
                onMoved: v => Config.motion.speed = v
            }
        }
        SettingRow {
            icon: "motion_photos_off"
            title: "Reduce motion"
            subtitle: "Short fades instead of springs (game mode does this too)"
            Switch {
                checked: Config.motion.reduce
                onToggled: on => Config.motion.reduce = on
            }
        }
    }

    Section {
        title: "Colors"
        note: "Colors come from the wallpaper (matugen) and recolor the shell, terminals, GTK, KDE, Zen and Vesktop."
        SettingRow {
            icon: "dark_mode"
            title: "Mode"
            Choice {
                model: [{ value: "dark", label: "Dark", icon: "dark_mode" }, { value: "light", label: "Light", icon: "light_mode" }]
                value: Config.theme.mode
                onPicked: v => ShellIpc.call("wallpaper", "mode", v)
            }
        }
        SettingRow {
            icon: "palette"
            title: "Scheme"
            subtitle: "How colors are drawn from the wallpaper"
        }
        Flow {
            x: 16
            width: parent.width - 32
            spacing: 8
            bottomPadding: 12
            Repeater {
                model: [["tonal-spot", "Tonal spot"], ["content", "Content"], ["expressive", "Expressive"], ["fidelity", "Fidelity"], ["fruit-salad", "Fruit salad"], ["monochrome", "Monochrome"], ["neutral", "Neutral"], ["rainbow", "Rainbow"], ["vibrant", "Vibrant"]]
                SButton {
                    required property var modelData
                    readonly property string scheme: "scheme-" + modelData[0]
                    text: modelData[1]
                    kind: Config.theme.scheme === scheme ? "filled" : "tonal"
                    onClicked: ShellIpc.call("wallpaper", "scheme", scheme)
                }
            }
        }
    }
}
