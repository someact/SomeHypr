pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core

// Region tools: screenshot, OCR, Lens, translate and record.
// start(mode) freezes the focused monitor with grim, capture/RegionSelector.qml
// shows the frozen frame while you pick a region (or click a window), and
// finish() crops it with magick and runs the action. Nothing stays loaded
// between captures.
Singleton {
    id: root

    // shot | ocr | lens | translate | record | recordSound
    readonly property var modes: [
        { id: "shot", icon: "screenshot_region", name: "Screenshot" },
        { id: "ocr", icon: "document_scanner", name: "Copy text" },
        { id: "lens", icon: "image_search", name: "Lens" },
        { id: "translate", icon: "translate", name: "Translate" },
        { id: "liveTranslate", icon: "g_translate", name: "Live translate" },
        { id: "record", icon: "screen_record", name: "Record" },
        { id: "recordSound", icon: "mic", name: "Record + sound" }
    ]
    property string mode: "shot"
    property bool selecting: false
    property string monitor: ""          // monitor the frozen frame came from
    property real scale: 1

    // Translate results, shown in the island's translate view
    property bool busy: false
    property string sourceText: ""
    property string translated: ""
    property string error: ""

    function start(m) {
        if (m.startsWith("record") && Recorder.active) {
            Recorder.stop();
            return;
        }
        if (Lock.locked)
            return;
        if (selecting) {
            mode = m;
            return;
        }
        mode = m;
        const mon = Hyprland.focusedMonitor;
        monitor = mon?.name ?? "";
        scale = mon?.scale ?? 1;
        // Let an open island collapse first so it is not in the frame
        if (UiState.expanded || UiState.overview || UiState.overlay) {
            UiState.close();
            UiState.overview = false;
            UiState.overlay = false;
            freezeDelay.restart();
        } else {
            freeze.running = true;
        }
    }

    function cancel() {
        selecting = false;
    }

    // r: { x, y, width, height } in the monitor's logical pixels; edit: right-button drag
    function finish(r, edit) {
        selecting = false;
        const s = scale;
        const g = `${Math.round(r.width * s)}x${Math.round(r.height * s)}+${Math.round(r.x * s)}+${Math.round(r.y * s)}`;
        const crop = `magick '${Paths.freeze}' -crop ${g} +repage`;
        if (r.width < 2 || r.height < 2)
            return;

        switch (mode) {
        case "shot":
            if (edit) {
                run(`${crop} png:- | swappy -f -`);
            } else if (Config.capture.saveShots) {
                const dir = Config.capture.shotDir || Paths.screenshots;
                run(`mkdir -p '${dir}' && f='${dir}'/Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png && ${crop} "$f" && wl-copy -t image/png < "$f"`);
                Osd.show("capture", "screenshot_region", -1, "Copied and saved");
            } else {
                run(`${crop} png:- | wl-copy -t image/png`);
                Osd.show("capture", "screenshot_region", -1, "Screenshot copied");
            }
            break;
        case "ocr":
            ocr.command = ["sh", "-c", `${crop} '${Paths.crop}' && tesseract '${Paths.crop}' stdout -l "$(tesseract --list-langs | awk 'NR>1 && $1!="osd"' | paste -sd+)" 2>/dev/null; rm -f '${Paths.crop}'`];
            ocr.running = true;
            break;
        case "translate":
            busy = true;
            sourceText = "";
            translated = "";
            error = "";
            UiState.open("translate");
            ocr.command = ["sh", "-c", `${crop} '${Paths.crop}' && tesseract '${Paths.crop}' stdout -l "$(tesseract --list-langs | awk 'NR>1 && $1!="osd"' | paste -sd+)" 2>/dev/null; rm -f '${Paths.crop}'`];
            ocr.running = true;
            break;
        case "lens":
            // Same flow as ii: upload to uguu.se (expires in 3 h), open Google Lens on the URL
            Osd.show("capture", "image_search", -1, "Uploading to Lens…");
            run(`${crop} '${Paths.crop}' && url=$(curl -sF files[]=@'${Paths.crop}' https://uguu.se/upload | jq -r '.files[0].url') && xdg-open "https://lens.google.com/uploadbyurl?url=$url"; rm -f '${Paths.crop}'`);
            break;
        case "liveTranslate":
            {
                // grim -g takes layout coordinates
                const mon = Hyprland.monitors.values.find(m => m.name === monitor);
                LiveTranslate.setArea(r.x + (mon?.x ?? 0), r.y + (mon?.y ?? 0), r.width, r.height, { x: mon?.x ?? 0, y: mon?.y ?? 0, width: (mon?.width ?? 1920) / (mon?.scale ?? 1), height: (mon?.height ?? 1080) / (mon?.scale ?? 1) });
                Osd.show("capture", "g_translate", -1, "Live translate on · Super+G to see the card");
            }
            break;
        case "record":
        case "recordSound":
            {
                // wf-recorder takes layout coordinates
                const mon = Hyprland.monitors.values.find(m => m.name === monitor);
                const geo = `${Math.round(r.x + (mon?.x ?? 0))},${Math.round(r.y + (mon?.y ?? 0))} ${Math.round(r.width)}x${Math.round(r.height)}`;
                recordGeometry = geo;
                recordDelay.restart();   // wait for the selector to leave the screen
            }
            break;
        }
    }

    // Re-run the translation with another target language (view buttons)
    function translate(text, to) {
        if (to)
            Config.capture.translateTo = to;
        if (!text.trim())
            return;
        busy = true;
        error = "";
        trans.command = ["trans", "-b", "-no-ansi", "-no-warn", ":" + Config.capture.translateTo, text];
        trans.running = true;
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    property string recordGeometry: ""
    Timer {
        id: recordDelay
        interval: 150
        onTriggered: Recorder.start(root.recordGeometry, root.mode === "recordSound")
    }

    Timer {
        id: freezeDelay
        interval: 320
        onTriggered: freeze.running = true
    }

    Process {
        id: freeze
        command: ["grim", "-o", root.monitor, Paths.freeze]
        onExited: code => {
            if (code === 0)
                root.selecting = true;
            else
                console.warn("Capture: grim failed", code);
        }
    }

    Process {
        id: ocr
        stdout: StdioCollector {
            id: ocrOut
        }
        onExited: {
            const text = ocrOut.text.trim();
            if (root.mode === "translate") {
                root.sourceText = text;
                if (text === "") {
                    root.busy = false;
                    root.error = "No text found";
                } else {
                    root.translate(text);
                }
                return;
            }
            if (text === "") {
                Osd.show("capture", "document_scanner", -1, "No text found");
                return;
            }
            Quickshell.execDetached(["wl-copy", "--", text]);
            Osd.show("capture", "document_scanner", -1, `Copied ${text.length} characters`);
        }
    }

    Process {
        id: trans
        stdout: StdioCollector {
            id: transOut
        }
        stderr: StdioCollector {
            id: transErr
        }
        onExited: code => {
            root.busy = false;
            root.translated = transOut.text.trim();
            if (code !== 0 || root.translated === "")
                root.error = transErr.text.trim().split("\n")[0] || "Translation failed (offline?)";
        }
    }
}
