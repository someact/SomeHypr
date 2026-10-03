pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// External monitor brightness over DDC/CI (ddcutil). Displays are detected once
// at start; the one in use follows the focused monitor (by DRM connector), else
// the first valid one. Writes are coalesced so dragging a slider sends one
// setvcp at a time.
Singleton {
    id: root

    property var displays: []      // [{ bus, connector }], valid DDC displays only
    readonly property string monitor: Hyprland.focusedMonitor?.name ?? ""
    readonly property string bus: {
        const d = displays.find(d => d.connector === monitor) ?? displays[0];
        return d ? d.bus : "";
    }
    property int max: 100
    property real value: 0.5       // 0..1, what the UI shows
    readonly property bool available: bus !== ""
    property bool _pending: false
    property bool _warned: false

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
    // Checks `bus` and sets the command here instead of using bindings: in
    // onBusChanged, `available` and a bound command have not caught up yet
    function read() {
        if (bus === "" || getter.running)
            return;
        getter.command = ["ddcutil", "-b", bus, "getvcp", "10", "--brief"];
        getter.running = true;
    }
    onBusChanged: read()

    // "detect --brief" prints one block per display; blocks headed "Invalid display"
    // (no DDC, e.g. a second input of the same monitor) must be skipped.
    Process {
        running: true
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const block of text.split(/\n\s*\n/)) {
                    const bus = block.match(/I2C bus:\s+\/dev\/i2c-(\d+)/);
                    if (!bus || /^\s*Invalid display/m.test(block))
                        continue;
                    const conn = block.match(/DRM connector:\s+card\d+-(\S+)/);
                    found.push({ bus: bus[1], connector: conn ? conn[1] : "" });
                }
                root.displays = found;
            }
        }
    }

    Process {
        id: getter
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
        stderr: StdioCollector {
            id: setterErr
        }
        onExited: code => {
            if (code !== 0) {
                if (!root._warned)
                    console.warn("Brightness: ddcutil setvcp on bus " + root.bus + " failed: " + setterErr.text.trim());
                root._warned = true;
                root._pending = false;
                root.read();    // show the level the monitor really has
                return;
            }
            if (root._pending) {
                root._pending = false;
                root.write();
            }
        }
    }
}
