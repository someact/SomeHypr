pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.core

// Session lock: state shared by every screen's lock surface (lock/LockScreen.qml)
// and the PAM conversation. `loginctl lock-session` → hypridle → scripts/lock.sh
// → `ipc call lock lock` lands here; lock.sh runs hyprlock if the shell does not
// answer, and Config.lock.useHyprlock hands every lock to hyprlock.
//
// The backdrop is the wallpaper blurred once by ImageMagick and cached, so the
// lock screen draws a plain image instead of a live blur.
Singleton {
    id: root

    property bool locked: false
    property bool preview: false        // same screen in a normal window, Esc closes (settings app)
    property bool unlocking: false      // exit animation is playing; the lock ends after it
    readonly property bool showing: locked || preview

    property string text: ""
    readonly property bool busy: pam.active
    property string error: ""           // last failure, shown under the field
    property bool backdropReady: false
    readonly property string userName: Quickshell.env("USER")
    property string face: ""            // ~/.face when it exists

    Process {
        running: true
        command: ["test", "-r", Paths.home + "/.face"]
        onExited: code => root.face = code === 0 ? Paths.home + "/.face" : ""
    }

    signal failed
    signal refocus

    function lock() {
        if (Config.lock.useHyprlock) {
            Quickshell.execDetached(["sh", "-c", "pidof hyprlock || exec hyprlock"]);
            return;
        }
        if (locked) {
            refocus();
            return;
        }
        reset();
        preview = false;
        UiState.close();
        UiState.overview = false;
        UiState.overlay = false;
        prepareBackdrop();
        locked = true;
    }

    function showPreview() {
        if (locked)
            return;
        reset();
        prepareBackdrop();
        preview = true;
    }

    function tryUnlock() {
        if (busy || unlocking || text === "")
            return;
        // The preview never asks PAM; Enter just closes it
        if (preview) {
            finish();
            return;
        }
        error = "";
        pam.start();
    }

    function reset() {
        if (pam.active)
            pam.abort();
        text = "";
        error = "";
        unlocking = false;
    }

    function finish() {
        unlocking = true;
        exitTimer.restart();
    }

    // Typed text is forgotten after 30 s without typing
    onTextChanged: {
        if (text !== "")
            error = "";
        clearTimer.restart();
    }
    Timer {
        id: clearTimer
        interval: 30000
        onTriggered: if (!root.busy) root.text = ""
    }

    // Exit animation first, then the compositor drops the lock
    Timer {
        id: exitTimer
        interval: Motion.reduced ? 120 : 380
        onTriggered: {
            root.locked = false;
            root.preview = false;
            root.unlocking = false;
            root.text = "";
        }
    }

    PamContext {
        id: pam
        // pam_unix asks for the password; other prompts (faillock) arrive as messages
        onPamMessage: {
            if (responseRequired)
                respond(root.text);
            else if (messageIsError)
                root.error = message;
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.finish();
                return;
            }
            root.text = "";
            if (root.error === "")
                root.error = "Wrong password";
            root.failed();
        }
        onError: err => {
            root.error = "Authentication error: " + PamError.toString(err);
            root.failed();
        }
    }

    // Blurred wallpaper, regenerated only when the wallpaper (or video frame) changed.
    // Downscale → blur → upscale is a fraction of the cost of a full-size blur.
    function prepareBackdrop() {
        const src = Wallpaper.isVideo ? Paths.videoFrame : Wallpaper.path;
        if (src === "" || !Config.lock.blur)
            return;
        if (blurProc.running) {
            blurProc.again = true;
            return;
        }
        const s = Quickshell.screens[0];
        const size = `${s?.width ?? 1920}x${s?.height ?? 1080}`;
        blurProc.command = ["sh", "-c", 'src="$1"; out="$2"; '
            + '[ -f "$out" ] && [ "$out" -nt "$src" ] && [ "$(cat "$out.src" 2>/dev/null)" = "$src" ] && exit 0; '
            + 'exit 3', "_", src, Paths.lockBlur];
        blurProc.build = ["sh", "-c", 'src="$1"; out="$2"; mkdir -p "${out%/*}"; '
            + 'magick "$src[0]" -resize "$3^" -gravity center -extent "$3" -resize 12.5% -blur 0x6 -resize 800% -quality 92 "$out.tmp.jpg" '
            + '&& mv -f "$out.tmp.jpg" "$out" && printf %s "$src" > "$out.src"', "_", src, Paths.lockBlur, size];
        blurProc.running = true;
    }
    Process {
        id: blurProc
        property var build: []
        property bool again: false
        property bool building: false
        onExited: code => {
            if (!building && code === 3) {
                // Stale: make it (the old image stays on screen until the new one is in)
                building = true;
                command = build;
                running = true;
                return;
            }
            if (building)
                root.backdropReady = false;     // reload the same path
            building = false;
            root.backdropReady = code === 0;
            if (again) {
                again = false;
                root.prepareBackdrop();
            }
        }
    }

    // Keep the cache warm: a few seconds after the wallpaper changes (after matugen)
    Connections {
        target: Wallpaper
        function onPathChanged() {
            warm.restart();
        }
    }
    Timer {
        id: warm
        interval: 4000
        onTriggered: if (!root.showing) root.prepareBackdrop()
    }
}
