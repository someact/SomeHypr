pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

// Cached 320×180 thumbnails for the wallpaper picker, made with ffmpeg (images
// and videos alike) one at a time, and only for files the picker asks about.
Singleton {
    id: root

    property var queue: []
    property var pending: ({})
    property var have: ({})        // thumbnail file name -> true, from one scan + each write
    property bool scanned: false
    property int revision: 0       // bumps when `have` changes

    function pathFor(file) {
        return Paths.thumbs + "/" + Qt.md5(file) + ".jpg";
    }
    // Thumbnail URL if it exists (queues it otherwise); "" until ready
    function url(file) {
        revision; // dependency
        if (!scanned)
            return "";
        const name = Qt.md5(file) + ".jpg";
        if (have[name])
            return "file://" + Paths.thumbs + "/" + name;
        Qt.callLater(request, file);
        return "";
    }
    function request(file) {
        if (pending[file])
            return;
        pending[file] = true;
        queue.push(file);
        next();
    }
    function next() {
        if (proc.running || queue.length === 0)
            return;
        const file = queue.shift();
        const video = Wallpaper.isVideoFile(file);
        proc.file = file;
        proc.command = ["sh", "-c", 'mkdir -p "$(dirname "$3")" && exec ffmpeg -loglevel error -y ' + (video ? "-ss 1 " : "") + '-i "$1" -frames:v 1 -vf "$2" -q:v 4 "$3"', "_", file, "scale=320:180:force_original_aspect_ratio=increase,crop=320:180", pathFor(file)];
        proc.running = true;
    }

    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$1" && ls -1 "$1"', "_", Paths.thumbs]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const n of text.split("\n"))
                    if (n !== "")
                        root.have[n] = true;
                root.scanned = true;
                root.revision++;
            }
        }
    }

    Process {
        id: proc
        property string file
        onExited: code => {
            if (code !== 0)
                console.warn("Thumbs: failed for", file);
            else
                root.have[Qt.md5(file) + ".jpg"] = true;
            root.revision++;
            root.next();
        }
    }
}
