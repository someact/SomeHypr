pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// The wallpaper: an image (drawn by wallpaper/WallpaperLayer.qml) or a video
// (played by mpvpaper). Every change re-themes the desktop through matugen;
// videos are themed from a frame grabbed with ffmpeg.
//
// mpvpaper pauses itself while the wallpaper is hidden or a window is
// fullscreen (-p -a FULL, which covers games and the lock screen); game mode
// also pauses it explicitly over mpv's IPC socket.
Singleton {
    id: root

    property string path: ""
    property string phase: ""          // last applied day/night phase (DayNight.qml)
    readonly property bool isVideo: isVideoFile(path)
    readonly property string mode: Config.theme.mode

    readonly property var imageExts: ["jpg", "jpeg", "png", "webp", "bmp", "avif"]
    readonly property var videoExts: ["mp4", "webm", "mkv", "mov", "m4v", "avi", "gif"]

    function ext(p) {
        return p.slice(p.lastIndexOf(".") + 1).toLowerCase();
    }
    function isVideoFile(p) {
        return videoExts.includes(ext(p));
    }
    function isWallpaperFile(p) {
        return imageExts.includes(ext(p)) || videoExts.includes(ext(p));
    }

    function set(file) {
        if (!file || !isWallpaperFile(file)) {
            console.warn("Wallpaper: not an image or video:", file);
            return;
        }
        path = file;
        save();
        if (isVideo) {
            frame.command = ["ffmpeg", "-loglevel", "error", "-y", "-ss", "1", "-i", file, "-frames:v", "1", "-vf", "scale=1280:-2", Paths.videoFrame];
            frame.running = true;
            startVideo();
        } else {
            stopVideo();
            theme(file);
        }
    }

    // Re-run matugen on the current wallpaper (after a mode or scheme change)
    function retheme() {
        if (path !== "")
            theme(isVideo ? Paths.videoFrame : path);
    }

    function toggleLightDark() {
        Config.theme.mode = mode === "dark" ? "light" : "dark";
        retheme();
    }

    function setMode(m) {
        if (m === mode)
            return;
        Config.theme.mode = m;
        retheme();
    }

    // Random wallpaper from a folder (default: ~/Pictures/Wallpapers)
    function random(folder) {
        randomProc.command = ["find", "-L", folder || Paths.wallpapers, "-maxdepth", "2", "-type", "f"];
        randomProc.running = true;
    }

    // Native file dialog for a wallpaper outside the picker folder
    function pick() {
        pickProc.running = true;
    }

    function theme(image) {
        Quickshell.execDetached(["matugen", "image", image, "-m", mode, "-t", Config.theme.scheme, "--source-color-index", "0"]);
    }

    function startVideo() {
        Quickshell.execDetached(["sh", "-c", 'pkill -x mpvpaper; exec mpvpaper -p -a FULL -o "no-audio loop hwdec=nvdec panscan=1.0 input-ipc-server=$2" ALL "$1"', "_", path, Paths.mpvSocket]);
        pauseSync.restart();
    }
    function stopVideo() {
        Quickshell.execDetached(["pkill", "-x", "mpvpaper"]);
    }

    function save() {
        Quickshell.execDetached(["mkdir", "-p", Paths.stateDir]);
        state.setText(JSON.stringify({ path: root.path, phase: root.phase }));
    }

    // Game mode pauses the video wallpaper even when the game is not fullscreen
    readonly property bool shouldPause: GameMode.active
    onShouldPauseChanged: pauseSync.restart()
    Timer {
        id: pauseSync
        interval: 600       // mpvpaper needs a moment to open its socket after start
        onTriggered: if (root.isVideo) {
            mpv.connected = false;
            mpv.connected = true;
        }
    }
    Socket {
        id: mpv
        path: Paths.mpvSocket
        onConnectionStateChanged: if (connected) {
            write(JSON.stringify({ command: ["set_property", "pause", root.shouldPause] }) + "\n");
            flush();
            connected = false;
        }
    }

    Process {
        id: frame
        onExited: code => {
            if (code === 0)
                root.theme(Paths.videoFrame);
            else
                console.warn("Wallpaper: could not grab a frame from", root.path);
        }
    }

    Process {
        id: pickProc
        command: ["kdialog", "--title", "Wallpaper", "--getopenfilename", Paths.wallpapers, "*.jpg *.jpeg *.png *.webp *.avif *.mp4 *.webm *.mkv *.mov *.gif|Images and videos"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.set(text.trim())
        }
    }

    Process {
        id: randomProc
        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.split("\n").filter(f => root.isWallpaperFile(f) && f !== root.path);
                if (files.length > 0)
                    root.set(files[Math.floor(Math.random() * files.length)]);
            }
        }
    }

    // Start mpvpaper at login if the saved wallpaper is a video
    Process {
        id: checkMpv
        command: ["pidof", "mpvpaper"]
        onExited: code => {
            if (code !== 0 && root.isVideo)
                root.startVideo();
        }
    }

    FileView {
        id: state
        path: Paths.wallpaperState
        printErrors: false
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.path = s.path ?? "";
                root.phase = s.phase ?? "";
            } catch (e) {}
            checkMpv.running = true;
        }
        onLoadFailed: migrate.reload()
    }

    // First run: take over the wallpaper ii last set
    FileView {
        id: migrate
        path: Paths.stateHome + "/quickshell/user/generated/wallpaper/path.txt"
        blockLoading: false
        printErrors: false
        onLoaded: {
            const p = text().trim();
            if (p !== "") {
                root.path = p;
                root.save();
            }
        }
    }
}
