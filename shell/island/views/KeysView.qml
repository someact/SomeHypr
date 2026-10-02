import QtQuick
import qs.core
import qs.services

// Keyboard shortcuts from bind descriptions (`hyprctl binds -j`).
FilterListView {
    id: root
    icon: "keyboard"
    placeholder: "Search shortcuts"
    maxRows: 10
    results: {
        const q = query.toLowerCase();
        return Keybinds.binds.filter(b => q === "" || (b.group + " " + b.action + " " + b.keys).toLowerCase().includes(q));
    }

    Component.onCompleted: Keybinds.refresh()

    delegate: ResultRow {
        required property var modelData
        icon: "keyboard_command_key"
        title: modelData.action
        subtitle: modelData.group
        hint: modelData.keys
        showHint: true
    }
}
