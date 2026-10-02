import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.components

// FPS limit for games running under MangoHud: writes `fps_limit` in
// ~/.config/MangoHud/MangoHud.conf, which MangoHud reloads on its own.
OverlayCard {
    id: root
    icon: "speed"
    title: "FPS limit"
    implicitWidth: 300

    readonly property var presets: [0, 30, 60, 90, 100, 120]
    property int current: 0

    FileView {
        id: conf
        path: Paths.mangohud
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.current = parseInt(text().match(/^fps_limit=(\d+)/m)?.[1] ?? "0")
    }

    function apply(fps) {
        root.current = fps;
        const f = Paths.mangohud;
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")"; touch "$1"; if grep -q "^fps_limit=" "$1"; then sed -i "s/^fps_limit=.*/fps_limit=$2/" "$1"; else echo "fps_limit=$2" >> "$1"; fi', "sh", f, String(fps)]);
    }

    Column {
        width: parent.width
        spacing: 8
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: root.presets
                PressButton {
                    id: preset
                    required property int modelData
                    width: 60
                    height: 32
                    radius: 16
                    color: Theme.islandRaised
                    active: root.current === modelData
                    onClicked: root.apply(modelData)
                    Label {
                        anchors.centerIn: parent
                        mono: preset.modelData > 0
                        text: preset.modelData > 0 ? preset.modelData : "Off"
                        color: preset.active ? Theme.fgPrimary : Theme.fgIsland
                    }
                }
            }
        }
        Label {
            width: parent.width
            text: "Games launched with mangohud (Steam: mangohud %command%)"
            color: Theme.fgIslandDim
            font.pixelSize: Theme.font.small
            wrapMode: Text.Wrap
        }
    }
}
