import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.components

// A floating pill in a top corner. The window is fixed-size so content changes
// never resize the surface; only the pill takes input and gets blurred.
PanelWindow {
    id: win

    required property ShellScreen modelData
    property bool left: true
    default property alias content: row.data
    property alias pill: pill

    screen: modelData
    WlrLayershell.namespace: "somehypr:pill"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.left: left
    anchors.right: !left
    implicitWidth: 640
    implicitHeight: Theme.barHeight + 8
    color: "transparent"

    mask: Region {
        item: pill
    }
    Region {
        id: blurArea
        item: pill
        radius: pill.radius
    }
    BackgroundEffect.blurRegion: Theme.glass && !GameMode.active ? blurArea : null

    GlassSurface {
        id: pill
        x: win.left ? 6 : win.width - width - 6
        y: UiState.hidden ? -height - 4 : 3
        height: Theme.barHeight - 6
        width: row.implicitWidth + 16
        Behavior on width {
            Spring { preset: "snappy" }
        }
        Behavior on y {
            Spring { preset: "snappy" }
        }

        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            spacing: 8
        }
    }
}
