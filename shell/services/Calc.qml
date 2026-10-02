pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Calculator for the search view, backed by qalc (math, units, currency).
// Runs only for input that looks like math, debounced while typing.
Singleton {
    id: root

    property string input: ""
    property string result: ""

    function looksLikeMath(t) {
        t = t.trim();
        if (t.startsWith("="))
            return t.length > 1;
        return /\d/.test(t) && /^[\d\s.,+\-*/^%()a-z]+$/i.test(t) && (/[+\-*/^%()]/.test(t) || / (to|in) /i.test(t));
    }

    function query(t) {
        input = t;
        if (!looksLikeMath(t)) {
            result = "";
            debounce.stop();
            return;
        }
        debounce.restart();
    }

    function copy() {
        if (result !== "")
            Quickshell.execDetached(["wl-copy", result]);
    }

    Timer {
        id: debounce
        interval: 120
        onTriggered: {
            proc.running = false;
            proc.command = ["qalc", "-t", root.input.replace(/^=/, "")];
            proc.running = true;
        }
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const r = text.trim();
                root.result = r !== "" && r !== root.input.trim() ? r : "";
            }
        }
    }
}
