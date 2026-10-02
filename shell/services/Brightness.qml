pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// External monitor brightness over DDC/CI (ddcutil). The bus is detected once
// at start; writes are coalesced so dragging a slider sends one setvcp at a time.
Singleton {
    id: root

    property string bus: ""
    property int max: 100
    property real value: 0.5       // 0..1, what the UI shows
    readonly property bool available: bus !== ""
    property bool _pending: false

    function set(v) {
        value = Math.max(0, Math.min(1, v));
        Osd.show("brightness", "light_mode", value);
        if (!available)
            return;
        if (setter.running)
            _pending = true;
        else
            write();
    }
    function increment() {
        set(value + 0.05);
    }
    function decrement() {
        set(value - 0.05);
    }
    function write() {
        setter.command = ["ddcutil", "-b", bus, "--noverify", "setvcp", "10", String(Math.round(value * max))];
        setter.running = true;
    }

    Process {
        running: true
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
                if (m) {
                    root.bus = m[1];
                    getter.running = true;
                }
            }
        }
    }

    Process {
        id: getter
        command: ["ddcutil", "-b", root.bus, "getvcp", "10", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "VCP 10 C <current> <max>"
                const p = text.trim().split(/\s+/);
                if (p.length >= 5) {
                    root.max = parseInt(p[4]) || 100;
                    root.value = (parseInt(p[3]) || 0) / root.max;
                }
            }
        }
    }

    Process {
        id: setter
        onExited: if (root._pending) {
            root._pending = false;
            root.write();
        }
    }
}
