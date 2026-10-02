import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.components
import qs.settings
import qs.settings.ui

Page {
    id: page
    title: "Apps & Autostart"
    subtitle: "Which apps the app keybinds open, and what starts with Hyprland."

    readonly property var apps: [
        { key: "terminal", name: "Terminal", icon: "terminal", keys: "Super + Enter" },
        { key: "fileManager", name: "File manager", icon: "folder", keys: "Super + E" },
        { key: "browser", name: "Browser", icon: "public", keys: "Super + W" },
        { key: "codeEditor", name: "Code editor", icon: "code", keys: "Super + C" },
        { key: "textEditor", name: "Text editor", icon: "edit_note", keys: "Super + X" },
        { key: "taskManager", name: "Task manager", icon: "monitoring", keys: "Ctrl + Shift + Esc" }
    ]
    property var defaults: ({})        // the user.lua values, read from Hyprland
    readonly property var autostart: HyprSettings.get("autostart", [])

    function setAutostart(list) {
        if (list.length === 0)
            HyprSettings.unset("autostart");
        else
            HyprSettings.set("autostart", list);
    }

    // What user.lua currently resolves each app to (with any override applied)
    Process {
        running: true
        command: ["hyprctl", "repl", "local o = {}; for _, k in ipairs({" + page.apps.map(a => JSON.stringify(a.key)).join(",") + "}) do o[#o + 1] = string.format('%q:%q', k, tostring(_G[k])) end; return '{' .. table.concat(o, ',') .. '}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.defaults = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Section {
        title: "Default apps"
        note: "A shell command. Leave empty to use the default from hypr/user.lua."
        Repeater {
            model: page.apps
            SettingRow {
                id: appRow
                required property var modelData
                readonly property string path: "apps." + modelData.key
                icon: modelData.icon
                title: modelData.name
                subtitle: modelData.keys
                changed: HyprSettings.isSet(path)
                onReset: HyprSettings.unset(path)
                Field {
                    implicitWidth: 340
                    mono: true
                    placeholder: HyprSettings.isSet(appRow.path) ? "" : (page.defaults[appRow.modelData.key] ?? "")
                    text: HyprSettings.isSet(appRow.path) ? HyprSettings.get(appRow.path, "") : ""
                    onCommitted: t => {
                        if (t.trim() === "")
                            HyprSettings.unset(appRow.path);
                        else if (t.trim() !== HyprSettings.get(appRow.path, ""))
                            HyprSettings.set(appRow.path, t.trim());
                    }
                }
            }
        }
    }

    Section {
        title: "Autostart"
        note: "Runs once when Hyprland starts, after the shell and session services (hypr/core/execs.lua)."
        Repeater {
            model: page.autostart
            SettingRow {
                id: entry
                required property var modelData
                required property int index
                icon: "play_arrow"
                title: modelData.command
                opacity: modelData.enabled === false ? 0.5 : 1
                Row {
                    spacing: 4
                    SButton {
                        kind: "text"
                        text: "Run now"
                        onClicked: Quickshell.execDetached(["sh", "-c", entry.modelData.command])
                    }
                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: entry.modelData.enabled !== false
                        onToggled: on => {
                            const list = page.autostart.slice();
                            list[entry.index] = { command: entry.modelData.command, enabled: on };
                            page.setAutostart(list);
                        }
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        icon: "delete"
                        iconSize: 18
                        iconColor: Theme.error
                        hoverColor: Theme.surfaceHigh
                        onClicked: page.setAutostart(page.autostart.filter((_, i) => i !== entry.index))
                    }
                }
            }
        }
        SettingRow {
            icon: "add"
            title: "Add a command"
            Row {
                spacing: 8
                Field {
                    id: newCommand
                    implicitWidth: 300
                    mono: true
                    placeholder: "e.g. vesktop --start-minimized"
                    onCommitted: t => {}
                }
                SButton {
                    text: "Add"
                    enabled: newCommand.text.trim() !== ""
                    onClicked: {
                        page.setAutostart(page.autostart.concat([{ command: newCommand.text.trim(), enabled: true }]));
                        newCommand.text = "";
                    }
                }
            }
        }
    }
}
