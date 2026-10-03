import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.components
import qs.services

// Quick launch: your most used apps (search frecency), topped up with the
// dock's pinned apps, eight at most.
DesktopWidget {
    id: root

    readonly property var apps: {
        const used = Apps.list.filter(a => Apps.rank(a.id) > 0).sort((a, b) => Apps.rank(b.id) - Apps.rank(a.id));
        const pinned = Config.dock.pinned.map(id => DesktopEntries.heuristicLookup(id)).filter(e => e && !used.includes(e));
        return used.concat(pinned).slice(0, 8);
    }

    Grid {
        columns: 4
        spacing: 6
        Repeater {
            model: root.apps
            PressButton {
                id: app
                required property DesktopEntry modelData
                width: 72
                height: 78
                radius: Theme.radius.normal
                color: "transparent"
                hoverColor: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
                onClicked: Apps.launch(modelData)
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        source: Apps.icon(app.modelData)
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 66
                        horizontalAlignment: Text.AlignHCenter
                        text: app.modelData.name
                        color: root.fg
                        font.pixelSize: Theme.font.small
                    }
                }
            }
        }
    }
    Label {
        visible: root.apps.length === 0
        text: "Apps you open from search show up here"
        color: root.fgDim
    }
}
