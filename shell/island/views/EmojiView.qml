import QtQuick
import qs.core
import qs.services

// Emoji search. Enter copies the emoji.
FilterListView {
    id: root
    icon: "mood"
    placeholder: "Search emoji"
    rowHeight: 40
    results: Emojis.loaded ? Emojis.query(query, 60) : []

    Component.onCompleted: Emojis.load()

    onActivated: i => {
        Emojis.copy(results[i]);
        UiState.close();
    }

    delegate: ResultRow {
        required property var modelData
        required property int index
        readonly property int space: modelData.indexOf(" ")
        glyph: modelData.slice(0, space)
        title: modelData.slice(space + 1)
        hint: "Copy"
        onClicked: root.activated(index)
    }
}
