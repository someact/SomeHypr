import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.services

// Live translator: keeps translating one screen area (LiveTranslate) while this
// card exists. Picking an area pins the card, so it stays over the game; close
// or unpin it to stop. While the overlay is open the area is outlined.
OverlayCard {
    id: root
    icon: "g_translate"
    title: "Live translate"
    implicitWidth: 400

    property ShellScreen overlayScreen: null

    readonly property var languages: [
        { code: "th", name: "ไทย" },
        { code: "en", name: "English" },
        { code: "ja", name: "日本語" }
    ]
    readonly property string langName: languages.find(l => l.code === Config.capture.translateTo)?.name ?? Config.capture.translateTo

    Component.onCompleted: LiveTranslate.watchers++
    Component.onDestruction: LiveTranslate.watchers--

    // The area in this window's coordinates
    readonly property rect area: LiveTranslate.hasArea
        ? Qt.rect(LiveTranslate.area.x - (overlayScreen?.x ?? 0), LiveTranslate.area.y - (overlayScreen?.y ?? 0), LiveTranslate.area.w, LiveTranslate.area.h)
        : Qt.rect(0, 0, 0, 0)
    // grim sees the overlay too: a card over the area would read its own text
    readonly property bool covers: LiveTranslate.hasArea && x < area.x + area.width && x + width > area.x && y < area.y + area.height && y + height > area.y

    // Area outline, only while the overlay is open (it would be read otherwise)
    Rectangle {
        parent: root      // not the card body (OverlayCard's default content): it would size the card
        visible: root.interactive && LiveTranslate.hasArea
        x: root.area.x - root.x - 3
        y: root.area.y - root.y - 3
        width: root.area.width + 6
        height: root.area.height + 6
        radius: 6
        color: "transparent"
        border.width: 2
        border.color: root.accent
        Label {
            anchors.bottom: parent.top
            anchors.bottomMargin: 4
            text: "Live translate area"
            font.pixelSize: Theme.font.small
            color: root.accent
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.7)
        }
    }

    Column {
        width: parent.width
        spacing: 8

        // Translation (outlined over the game when pinned)
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            maximumLineCount: 6
            text: !LiveTranslate.hasArea ? "Pick an area of the screen to translate"
                : LiveTranslate.translated !== "" ? LiveTranslate.translated
                : LiveTranslate.status === "reading" ? "Reading…"
                : LiveTranslate.status === "translating" ? "Translating…"
                : LiveTranslate.paused ? "Paused"
                : "Waiting for text in the area"
            color: LiveTranslate.translated !== "" ? Theme.fgIsland : Theme.fgIslandDim
            font.pixelSize: root.interactive ? Theme.font.normal : Theme.font.large
            style: root.interactive ? Text.Normal : Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.7)
        }

        // Source text and state, only while the overlay is open
        Label {
            visible: root.interactive && LiveTranslate.source !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            maximumLineCount: 3
            text: LiveTranslate.source
            color: Theme.fgIslandDim
            font.pixelSize: Theme.font.small
        }
        Label {
            visible: root.interactive && (LiveTranslate.error !== "" || root.covers)
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.covers ? "Move this card off the area: it would read itself" : LiveTranslate.error
            color: "#ff8a80"
            font.pixelSize: Theme.font.small
        }

        Row {
            visible: root.interactive
            spacing: 6
            PressButton {
                width: pickRow.implicitWidth + 20
                height: 32
                radius: 16
                color: Theme.islandRaised
                onClicked: LiveTranslate.pick()
                Row {
                    id: pickRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "select"
                        size: 17
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: LiveTranslate.hasArea ? "New area" : "Pick area"
                    }
                }
            }
            PressButton {
                width: langLabel.implicitWidth + 24
                height: 32
                radius: 16
                color: Theme.islandRaised
                onClicked: {
                    const codes = root.languages.map(l => l.code);
                    Config.capture.translateTo = codes[(codes.indexOf(Config.capture.translateTo) + 1) % codes.length];
                }
                Label {
                    id: langLabel
                    anchors.centerIn: parent
                    text: "→ " + root.langName
                }
            }
            IconButton {
                visible: LiveTranslate.hasArea
                width: 32
                height: 32
                iconSize: 18
                icon: LiveTranslate.paused ? "play_arrow" : "pause"
                active: LiveTranslate.paused
                activeColor: root.accent
                iconColor: active ? root.onAccent : Theme.fgIsland
                onClicked: LiveTranslate.paused = !LiveTranslate.paused
            }
            IconButton {
                visible: LiveTranslate.translated !== ""
                width: 32
                height: 32
                iconSize: 18
                icon: "content_copy"
                onClicked: Quickshell.execDetached(["wl-copy", "--", LiveTranslate.translated])
            }
        }
    }
}
