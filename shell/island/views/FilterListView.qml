import QtQuick
import qs.core
import qs.components

// Search field over a KeyNavList; base for clipboard, emoji and keys views.
// Set `results` from `query`; handle `activated(index)`.
FocusScope {
    id: root

    property alias query: field.text
    property alias placeholder: field.placeholder
    property alias icon: field.icon
    property alias list: list
    property alias delegate: list.delegate
    property var results: []
    property int rowHeight: 48
    property int maxRows: 8
    property var extraKey: null      // (event) => bool, for view-specific keys

    signal activated(int index)

    implicitWidth: 600
    implicitHeight: field.height + 8 + Math.max(list.contentHeight > 0 ? Math.min(list.contentHeight, rowHeight * maxRows) : 40, 40)

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Up:
            list.up();
            return true;
        case Qt.Key_Down:
            list.down();
            return true;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            list.activate();
            return true;
        case Qt.Key_Left:
        case Qt.Key_Right:
            if (query !== "")
                return false;
            break;
        }
        if (extraKey && extraKey(event))
            return true;
        return UiState.navKey(event);
    }

    Component.onCompleted: field.focusInput()

    SearchField {
        id: field
        width: parent.width
        focus: true
        keyHandler: root.handleKey
    }

    KeyNavList {
        id: list
        anchors.top: field.bottom
        anchors.topMargin: 8
        width: parent.width
        height: Math.min(contentHeight, root.rowHeight * root.maxRows)
        model: root.results
        onActivated: i => root.activated(i)
    }

    Label {
        anchors.top: field.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.results.length === 0
        text: "Nothing here"
        color: Theme.fgIslandDim
    }
}
