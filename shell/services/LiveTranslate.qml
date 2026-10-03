pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Live area translator: a screen area (Config.overlay.translateArea, picked with
// Capture "liveTranslate") read again and again while its overlay card exists.
// Each tick is one chain, never two at once:
//   1. grim the area into a 64×24 posterized gray thumbnail and hash it;
//      unchanged pixels → stop here (the usual case, a few ms)
//   2. OCR the area (2× upscaled) with tesseract; unchanged text → stop
//   3. translate-shell into Config.capture.translateTo
Singleton {
    id: root

    readonly property var area: Config.overlay.translateArea
    readonly property bool hasArea: (area?.w ?? 0) > 1 && (area?.h ?? 0) > 1
    readonly property string geometry: hasArea ? `${area.x},${area.y} ${area.w}x${area.h}` : ""

    property int watchers: 0          // the overlay card raises this while it exists
    property bool paused: false
    // Not while the overlay is open: its cards, outline and dimming would be read too
    readonly property bool running: hasArea && watchers > 0 && !paused && !Lock.locked && !UiState.overlay

    // idle | reading | translating | error
    property string status: "idle"
    property string source: ""        // last OCR text
    property string translated: ""
    property string error: ""
    property string hash: ""

    readonly property string langs: '"$(tesseract --list-langs 2>/dev/null | awk \'NR>1 && $1!="osd"\' | paste -sd+)"'

    onGeometryChanged: reset()
    // Back from the overlay: read the area fresh
    onRunningChanged: if (running) hash = ""
    function reset() {
        hash = "";
        source = "";
        translated = "";
        error = "";
        status = "idle";
    }
    // Language changed: translate the text we already have again
    Connections {
        target: Config.capture
        function onTranslateToChanged() {
            if (root.source !== "" && !step.running)
                root.translate();
        }
    }

    Timer {
        interval: 1500
        repeat: true
        triggeredOnStart: true
        running: root.running
        onTriggered: if (!step.running) root.check()
    }

    function check() {
        step.phase = "hash";
        step.command = ["sh", "-c", 'grim -g "$1" -t ppm - | magick ppm:- -resize "64x24!" -colorspace gray -posterize 6 gray:- | md5sum | cut -c1-32', "_", geometry];
        step.running = true;
    }
    function read() {
        status = "reading";
        step.phase = "ocr";
        step.command = ["sh", "-c", 'grim -g "$1" -t png - | magick png:- -resize 200% -colorspace gray png:- | tesseract stdin stdout -l ' + langs + ' 2>/dev/null', "_", geometry];
        step.running = true;
    }
    function translate() {
        status = "translating";
        step.phase = "trans";
        step.command = ["trans", "-b", "-no-ansi", "-no-warn", ":" + Config.capture.translateTo, source];
        step.running = true;
    }

    Process {
        id: step
        property string phase: ""
        stdout: StdioCollector {
            id: out
        }
        onExited: code => {
            const text = out.text.trim();
            switch (phase) {
            case "hash":
                if (code === 0 && text !== "" && text !== root.hash) {
                    root.hash = text;
                    root.read();
                }
                break;
            case "ocr":
                {
                    // Joined lines, as games wrap subtitles
                    const src = text.replace(/\s*\n\s*/g, " ").replace(/\s+/g, " ").trim();
                    if (src === root.source) {
                        root.status = "idle";
                    } else if (src === "") {
                        root.source = "";
                        root.translated = "";
                        root.status = "idle";
                    } else {
                        root.source = src;
                        root.translate();
                    }
                }
                break;
            case "trans":
                if (code !== 0 || text === "") {
                    root.error = "translate-shell failed (offline?)";
                    root.status = "error";
                    root.hash = "";   // try again on the next tick
                } else {
                    root.translated = text;
                    root.error = "";
                    root.status = "idle";
                }
                break;
            }
        }
    }

    // From Capture.finish: layout-pixel rectangle of the picked area, and the
    // monitor's layout rect. The card is pinned (so it stays over the game) and
    // placed just below the area, or above it, never over it: grim sees the
    // overlay too, and a card on the area would read its own translation.
    function setArea(x, y, w, h, mon) {
        Config.overlay.translateArea = { x: Math.round(x), y: Math.round(y), w: Math.round(w), h: Math.round(h) };
        paused = false;
        reset();
        const cardW = 400, cardH = 200, gap = 16;
        const lx = x - mon.x, ly = y - mon.y;
        const below = ly + h + gap + cardH <= mon.height;
        const pos = Object.assign({}, Config.overlay.positions ?? {});
        pos.translate = {
            x: Math.round(Math.max(8, Math.min(mon.width - cardW - 8, lx + w / 2 - cardW / 2))),
            y: Math.round(below ? ly + h + gap : Math.max(8, ly - gap - cardH))
        };
        Config.overlay.positions = pos;
        const open = Array.from(Config.overlay.open), pinned = Array.from(Config.overlay.pinned);
        Config.overlay.open = open.includes("translate") ? open : [...open, "translate"];
        Config.overlay.pinned = pinned.includes("translate") ? pinned : [...pinned, "translate"];
    }
    function pick() {
        Capture.start("liveTranslate");
    }
}
