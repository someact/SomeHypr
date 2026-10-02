import QtQuick
import Quickshell
import qs.core
import qs.components
import qs.services
import qs.commands

// Super tap: apps (fuzzy + frecency), calculator, open windows, and `/commands`.
FocusScope {
    id: root

    readonly property string text: field.text
    readonly property bool commandMode: text.startsWith("/")
    property var results: []

    implicitWidth: 600
    implicitHeight: field.height + (results.length > 0 ? list.height + 8 : 0)

    function rebuild() {
        // Read field.text directly: bindings derived from it may not have
        // updated yet when this runs from onTextChanged
        const text = field.text;
        const max = Config.search.maxResults;
        const out = [];
        if (text.startsWith("/")) {
            const p = Commands.parse(text);
            if (p.complete && p.command) {
                const c = p.command;
                out.push({ icon: c.icon, title: "/" + c.name + (p.arg ? " " + p.arg : ""), subtitle: c.description, hint: "Enter", keepOpen: c.keepOpen, run: () => c.run(p.arg) });
                for (const s of c.suggest(p.arg))
                    out.push({ icon: c.icon, title: "/" + c.name + " " + s.label, subtitle: "", hint: "Enter", keepOpen: c.keepOpen, complete: "/" + c.name + " " + s.value, run: () => c.run(s.value) });
            } else {
                for (const c of Commands.matching(p.name))
                    out.push({ icon: c.icon, title: "/" + c.name + (c.args ? "  " + c.args : ""), subtitle: c.description, hint: c.args ? "Tab" : "Enter", keepOpen: c.keepOpen, complete: "/" + c.name + " ", run: () => c.run("") });
            }
        } else {
            if (Calc.result !== "")
                out.push({ icon: "calculate", title: Calc.result, subtitle: "Copy result", hint: "Enter", mono: true, run: () => Calc.copy() });
            const q = text.trim().toLowerCase();
            if (q !== "") {
                const wins = HyprData.windows.filter(w => (w.title ?? "").toLowerCase().includes(q) || (w.wayland?.appId ?? "").toLowerCase().includes(q)).slice(0, 3);
                for (const w of wins)
                    out.push({ iconSource: HyprData.appIcon(w.wayland?.appId ?? ""), title: w.title, subtitle: "Window · workspace " + (w.workspace?.name ?? "?"), hint: "Focus", run: () => HyprData.focusWindow(w) });
            }
            for (const a of Apps.query(text, max))
                out.push({ iconSource: Apps.icon(a), title: a.name, subtitle: a.genericName || a.comment || "", hint: "Open", run: () => Apps.launch(a) });
        }
        results = out.slice(0, max + 3);
        list.currentIndex = 0;
    }

    function activate(i) {
        const r = results[i];
        if (!r)
            return;
        if (r.complete && field.text.startsWith("/") && !Commands.parse(field.text).complete && Commands.parse(r.complete).command?.args) {
            field.text = r.complete;    // needs an argument: complete instead of running
            return;
        }
        if (!r.keepOpen)
            UiState.close();
        r.run();
    }

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
            activate(list.currentIndex);
            return true;
        case Qt.Key_Tab:
            {
                const r = results[list.currentIndex];
                if (r?.complete)
                    field.text = r.complete;
                return true;
            }
        case Qt.Key_Left:
        case Qt.Key_Right:
            if (text !== "")
                return false;
            UiState.step(event.key === Qt.Key_Left ? -1 : 1);
            return true;
        case Qt.Key_Escape:
            UiState.close();
            return true;
        }
        return false;
    }

    onTextChanged: {
        Calc.query(text);
        rebuild();
    }
    Connections {
        target: Commands
        function onRevisionChanged() {
            root.rebuild();
        }
    }
    Connections {
        target: Apps
        function onListChanged() {
            root.rebuild();
        }
    }
    Connections {
        target: Calc
        function onResultChanged() {
            root.rebuild();
        }
    }
    Connections {
        target: UiState
        function onSearchReset() {
            field.text = UiState.searchText;
            field.focusInput();
        }
    }
    Component.onCompleted: {
        field.text = UiState.searchText;
        rebuild();
        field.focusInput();
    }

    SearchField {
        id: field
        width: parent.width
        focus: true
        placeholder: "Search apps and windows · = math · / commands"
        icon: root.commandMode ? "terminal" : "search"
        keyHandler: root.handleKey
    }

    KeyNavList {
        id: list
        anchors.top: field.bottom
        anchors.topMargin: 8
        width: parent.width
        height: Math.min(contentHeight, 9 * 48)
        model: root.results
        onActivated: i => root.activate(i)

        delegate: ResultRow {
            required property var modelData
            required property int index
            icon: modelData.icon ?? ""
            iconSource: modelData.iconSource ?? ""
            title: modelData.title
            subtitle: modelData.subtitle ?? ""
            hint: modelData.hint ?? ""
            monoTitle: modelData.mono ?? false
            onClicked: root.activate(index)
        }
    }
}
