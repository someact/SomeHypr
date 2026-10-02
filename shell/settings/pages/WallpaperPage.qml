import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    id: page
    title: "Wallpaper"
    subtitle: "Images and videos. Colors follow the wallpaper."

    // The shell owns the wallpaper (mpvpaper, matugen); this page reads its state
    // and asks it to change over IPC.
    property string current: ""
    readonly property bool isVideo: /\.(mp4|webm|mkv|mov|m4v|avi|gif)$/i.test(current)
    readonly property var schedule: Config.theme.schedule

    FileView {
        path: Paths.wallpaperState
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                page.current = JSON.parse(text()).path ?? "";
            } catch (e) {}
        }
    }

    // Folder chooser for the day/night sets; `target` is the schedule key to fill
    Process {
        id: folderDialog
        property string target
        command: ["kdialog", "--title", "Wallpaper folder", "--getexistingdirectory", Paths.wallpapers]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") page.schedule[folderDialog.target] = text.trim()
        }
    }
    function chooseFolder(key) {
        folderDialog.target = key;
        folderDialog.running = true;
    }

    Section {
        title: "Current"
        Item {
            width: parent.width
            height: 236
            Cover {
                id: preview
                x: 16
                y: 16
                width: 360
                height: 204
                radius: Theme.radius.normal
                color: Theme.surfaceHigh
                fallbackIcon: "wallpaper"
                source: page.current === "" ? "" : Paths.url(page.isVideo ? Paths.videoFrame : page.current)
            }
            Column {
                anchors.left: preview.right
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: 16
                spacing: 10
                SText {
                    width: parent.width
                    text: page.current === "" ? "No wallpaper set" : page.current.split("/").pop()
                    font.weight: Font.DemiBold
                }
                SText {
                    width: parent.width
                    text: page.isVideo ? "Video (mpvpaper, paused while a game or fullscreen window is up)" : page.current.slice(0, page.current.lastIndexOf("/"))
                    dim: true
                    font.pixelSize: Theme.font.small
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
                Item {
                    width: 1
                    height: 6
                }
                SButton {
                    kind: "filled"
                    icon: "photo_library"
                    text: "Choose…"
                    onClicked: ShellIpc.call("island", "open", "wallpaper")
                }
                Row {
                    spacing: 8
                    SButton {
                        icon: "shuffle"
                        text: "Random"
                        onClicked: ShellIpc.call("wallpaper", "random")
                    }
                    SButton {
                        icon: "folder_open"
                        text: "From file…"
                        onClicked: ShellIpc.call("wallpaper", "pick")
                    }
                }
            }
        }
    }

    Section {
        title: "Day and night"
        note: "At each switch time the wallpaper changes to a random one from that folder (empty: keep the current one) and colors switch mode."
        SettingRow {
            icon: "routine"
            title: "Switch on a schedule"
            Switch {
                checked: page.schedule.enabled
                onToggled: on => page.schedule.enabled = on
            }
        }
        Repeater {
            model: [{ key: "day", name: "Day", icon: "light_mode" }, { key: "night", name: "Night", icon: "dark_mode" }]
            Column {
                id: phase
                required property var modelData
                width: parent.width
                enabled: page.schedule.enabled
                opacity: enabled ? 1 : 0.45

                SettingRow {
                    icon: phase.modelData.icon
                    title: phase.modelData.name + " starts at"
                    Field {
                        implicitWidth: 90
                        mono: true
                        text: page.schedule[phase.modelData.key + "Start"]
                        onCommitted: t => {
                            if (/^\d{1,2}:\d{2}$/.test(t.trim()))
                                page.schedule[phase.modelData.key + "Start"] = t.trim().padStart(5, "0");
                        }
                    }
                }
                SettingRow {
                    icon: "contrast"
                    title: phase.modelData.name + " colors"
                    Choice {
                        model: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }]
                        value: page.schedule[phase.modelData.key + "Mode"]
                        onPicked: v => page.schedule[phase.modelData.key + "Mode"] = v
                    }
                }
                SettingRow {
                    icon: "folder"
                    title: phase.modelData.name + " wallpapers"
                    subtitle: page.schedule[phase.modelData.key + "Folder"] || "Keep the current wallpaper"
                    Row {
                        spacing: 4
                        SButton {
                            kind: "text"
                            text: "Clear"
                            visible: page.schedule[phase.modelData.key + "Folder"] !== ""
                            onClicked: page.schedule[phase.modelData.key + "Folder"] = ""
                        }
                        SButton {
                            text: "Choose…"
                            onClicked: page.chooseFolder(phase.modelData.key + "Folder")
                        }
                    }
                }
            }
        }
        SettingRow {
            enabled: page.schedule.enabled
            icon: "nightlight"
            title: "Night light at night"
            subtitle: "Warmer screen (hyprsunset) during the night phase"
            Switch {
                checked: page.schedule.nightLight
                onToggled: on => page.schedule.nightLight = on
            }
        }
    }
}
