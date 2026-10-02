import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import "../lib/fuzzysort.js" as Fuzzy

Command {
    id: root
    name: "project"
    icon: "folder_code"
    args: "<name>"
    description: "Open a project in the code editor"

    property var projects: []
    property string editor: "code"

    function run(arg) {
        const hit = suggest(arg)[0];
        if (hit)
            Quickshell.execDetached(["sh", "-c", root.editor + ' "$1"', "_", Paths.projects + "/" + hit.value]);
    }
    function suggest(arg) {
        if (projects.length === 0)
            scan.running = true;
        if (arg === "")
            return projects.slice(0, 8).map(p => ({ label: p, value: p }));
        return Fuzzy.go(arg, projects, { limit: 8 }).map(r => ({ label: r.target, value: r.target }));
    }

    // Project list and the editor from hypr/user.lua, read once on first use
    property Process scan: Process {
        command: ["sh", "-c", 'ls -1 "$1"; echo "--editor--"; hyprctl repl "return codeEditor"', "_", Paths.projects]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("--editor--");
                root.projects = parts[0].split("\n").filter(s => s !== "");
                const ed = (parts[1] ?? "").trim();
                if (ed !== "" && ed !== "nil")
                    root.editor = ed;
                root.revision++;
            }
        }
    }
}
