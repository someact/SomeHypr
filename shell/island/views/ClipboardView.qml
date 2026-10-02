import QtQuick
import qs.core
import qs.services

// cliphist history. Enter copies, Delete removes, type to filter.
FilterListView {
    id: root
    icon: "content_paste"
    placeholder: "Clipboard history"
    results: Clipboard.entries.filter(e => query === "" || e.text.toLowerCase().includes(query.toLowerCase())).slice(0, 200)

    Component.onCompleted: Clipboard.refresh()

    onActivated: i => {
        Clipboard.copy(results[i]);
        UiState.close();
    }
    extraKey: event => {
        if (event.key === Qt.Key_Delete) {
            const e = results[list.currentIndex];
            if (e)
                Clipboard.remove(e);
            return true;
        }
        return false;
    }

    delegate: ResultRow {
        required property var modelData
        required property int index
        icon: modelData.isImage ? "image" : "notes"
        title: modelData.isImage ? modelData.text.replace(/^\[\[ binary data /, "").replace(/ \]\]$/, "") : modelData.text.replace(/\s+/g, " ")
        hint: "Copy"
        onClicked: root.activated(index)
        onRightClicked: Clipboard.remove(modelData)
    }
}
