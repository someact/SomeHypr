pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, RAM and GPU usage. Nothing runs unless a view raises `watchers`; then
// /proc is read every second and nvidia-smi streams once a second.
Singleton {
    id: root

    property int watchers: 0
    readonly property bool active: watchers > 0

    property real cpu: 0
    property real cpuTemp: 0
    property real mem: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real gpu: 0
    property real gpuTemp: 0
    property real vram: 0
    property var _lastCpu: null
    property string _tempPath: ""

    Timer {
        running: root.active
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root._tempPath !== "")
                temp.reload();
        }
    }

    FileView {
        id: stat
        path: root.active ? "/proc/stat" : ""
        onLoaded: {
            const p = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = p[3] + p[4];
            const total = p.reduce((a, b) => a + b, 0);
            if (root._lastCpu) {
                const dt = total - root._lastCpu.total;
                root.cpu = dt > 0 ? 1 - (idle - root._lastCpu.idle) / dt : 0;
            }
            root._lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: root.active ? "/proc/meminfo" : ""
        onLoaded: {
            const t = text();
            const kb = k => parseInt(t.match(new RegExp(k + ":\\s+(\\d+)"))?.[1] ?? "0");
            const total = kb("MemTotal"), avail = kb("MemAvailable");
            root.memTotalGb = total / 1048576;
            root.memUsedGb = (total - avail) / 1048576;
            root.mem = total > 0 ? (total - avail) / total : 0;
        }
    }

    FileView {
        id: temp
        path: root.active && root._tempPath !== "" ? root._tempPath : ""
        onLoaded: root.cpuTemp = parseInt(text()) / 1000
    }

    // Find the k10temp (Ryzen) sensor once
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = k10temp ] && echo $h/temp1_input && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root._tempPath = text.trim()
        }
    }

    Process {
        running: root.active
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits", "-lms", "1000"]
        stdout: SplitParser {
            onRead: line => {
                const p = line.split(",").map(s => parseFloat(s));
                if (p.length < 4)
                    return;
                root.gpu = p[0] / 100;
                root.gpuTemp = p[1];
                root.vram = p[3] > 0 ? p[2] / p[3] : 0;
            }
        }
    }
}
