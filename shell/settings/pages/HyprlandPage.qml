import QtQuick
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    title: "Hyprland"
    subtitle: "Compositor options. Only what you change here is saved (hypr.json) and applied last, over the defaults in hypr/core/. The reset arrow drops your value."

    Section {
        title: "Layout"
        OptionSlider {
            path: "general.gaps_in"
            icon: "padding"
            title: "Gaps between windows"
            to: 20
        }
        OptionSlider {
            path: "general.gaps_out"
            icon: "fit_screen"
            title: "Gaps around the screen"
            to: 40
        }
        OptionSlider {
            path: "general.border_size"
            icon: "border_style"
            title: "Border"
            to: 6
        }
        OptionSlider {
            path: "decoration.rounding"
            icon: "rounded_corner"
            title: "Corner rounding"
            to: 30
        }
        OptionChoice {
            path: "general.layout"
            icon: "dashboard"
            title: "Tiling layout"
            model: [{ value: "dwindle", label: "Dwindle" }, { value: "master", label: "Master" }]
        }
    }

    Section {
        title: "Effects"
        note: "Game mode still turns blur, shadows and animations off while a game is fullscreen, and restores your choice afterwards."
        OptionSwitch {
            path: "decoration.blur.enabled"
            icon: "blur_on"
            title: "Blur"
        }
        OptionSlider {
            path: "decoration.blur.size"
            icon: "blur_medium"
            title: "Blur size"
            from: 1
            to: 12
        }
        OptionSlider {
            path: "decoration.blur.passes"
            icon: "layers"
            title: "Blur passes"
            subtitle: "More passes look smoother and cost more GPU"
            from: 1
            to: 4
        }
        OptionSwitch {
            path: "decoration.shadow.enabled"
            icon: "shadow"
            title: "Shadows"
        }
        OptionSwitch {
            path: "decoration.dim_inactive"
            icon: "brightness_6"
            title: "Dim unfocused windows"
        }
        OptionSwitch {
            path: "animations.enabled"
            icon: "animation"
            title: "Animations"
        }
    }

    Section {
        title: "Input"
        OptionSlider {
            path: "input.sensitivity"
            icon: "mouse"
            title: "Pointer speed"
            from: -1
            to: 1
            stepSize: 0.05
        }
        OptionChoice {
            path: "input.follow_mouse"
            icon: "ads_click"
            title: "Focus follows mouse"
            model: [{ value: 0, label: "Off" }, { value: 1, label: "Always" }, { value: 2, label: "Detached" }, { value: 3, label: "Click" }]
        }
        OptionSlider {
            path: "input.repeat_rate"
            icon: "keyboard"
            title: "Key repeat rate"
            from: 10
            to: 60
            suffix: "/s"
        }
        OptionSlider {
            path: "input.repeat_delay"
            icon: "timer"
            title: "Key repeat delay"
            from: 150
            to: 800
            stepSize: 25
            suffix: " ms"
        }
    }

    Section {
        title: "Touchpad"
        visible: HyprSettings.hasTouchpad
        OptionSwitch {
            path: "input.touchpad.natural_scroll"
            icon: "swipe_vertical"
            title: "Natural scrolling"
            subtitle: "Content follows your fingers"
        }
        OptionSwitch {
            path: "input.touchpad.tap_to_click"
            icon: "touch_app"
            title: "Tap to click"
        }
        OptionSwitch {
            path: "input.touchpad.clickfinger_behavior"
            icon: "ads_click"
            title: "Click with fingers"
            subtitle: "Pressing with two fingers is a right click, three a middle click (instead of by area)"
        }
        OptionSwitch {
            path: "input.touchpad.disable_while_typing"
            icon: "keyboard_hide"
            title: "Off while typing"
        }
        OptionSlider {
            path: "input.touchpad.scroll_factor"
            icon: "unfold_more"
            title: "Scroll speed"
            from: 0.1
            to: 2
            stepSize: 0.05
        }
        SettingRow {
            icon: "swipe"
            title: "Gestures"
            subtitle: "4 fingers: sideways switches workspace, up or down opens the overview. 3 fingers: drag moves a window, pinch toggles fullscreen"
            changed: HyprSettings.isSet("touchpad.gestures")
            onReset: HyprSettings.unset("touchpad.gestures")
            Switch {
                checked: HyprSettings.get("touchpad.gestures", true)
                onToggled: on => HyprSettings.set("touchpad.gestures", on)
            }
        }
    }

    Section {
        title: "Display"
        OptionChoice {
            path: "misc.vrr"
            icon: "sync"
            title: "Adaptive sync (VRR)"
            model: [{ value: 0, label: "Off" }, { value: 1, label: "On" }, { value: 2, label: "Fullscreen only" }]
        }
    }

    component OptionSlider: SettingRow {
        id: os
        required property string path
        property real from: 0
        property real to: 10
        property real stepSize: 1
        property string suffix: ""
        readonly property string key: "hyprland." + path
        changed: HyprSettings.isSet(key)
        onReset: HyprSettings.unset(key)
        ValueSlider {
            from: os.from
            to: os.to
            stepSize: os.stepSize
            suffix: os.suffix
            value: Number(HyprSettings.get(os.key, os.from))
            onMoved: v => HyprSettings.set(os.key, v)
        }
    }
    component OptionSwitch: SettingRow {
        id: sw
        required property string path
        readonly property string key: "hyprland." + path
        changed: HyprSettings.isSet(key)
        onReset: HyprSettings.unset(key)
        Switch {
            checked: HyprSettings.get(sw.key, false) === true
            onToggled: on => HyprSettings.set(sw.key, on)
        }
    }
    component OptionChoice: SettingRow {
        id: oc
        required property string path
        property var model: []
        readonly property string key: "hyprland." + path
        changed: HyprSettings.isSet(key)
        onReset: HyprSettings.unset(key)
        Choice {
            model: oc.model
            value: HyprSettings.get(oc.key, null)
            onPicked: v => HyprSettings.set(oc.key, v)
        }
    }
}
