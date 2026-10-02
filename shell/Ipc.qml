import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import qs.services

// `qs -c somehypr ipc call <target> <function> [args]`
Scope {
    IpcHandler {
        target: "island"
        function open(view: string): void {
            UiState.open(view);
        }
        function toggle(view: string): void {
            UiState.toggle(view);
        }
        function search(text: string): void {
            UiState.open("search", text);
        }
        function close(): void {
            UiState.close();
        }
        function hide(): void {
            UiState.hidden = !UiState.hidden;
        }
        function state(): string {
            return JSON.stringify({ expanded: UiState.expanded, view: UiState.view, ambient: UiState.ambient });
        }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void {
            UiState.toggleOverview();
        }
        function open(): void {
            if (!UiState.overview)
                UiState.toggleOverview();
        }
        function close(): void {
            UiState.overview = false;
        }
    }

    // mode: shot | ocr | lens | translate | record | recordSound
    IpcHandler {
        target: "capture"
        function region(mode: string): void {
            Capture.start(mode || "shot");
        }
        function screen(sound: bool): void {
            Recorder.toggleScreen(sound);
        }
        function stop(): void {
            Recorder.stop();
        }
        function recording(): bool {
            return Recorder.active;
        }
    }

    IpcHandler {
        target: "overlay"
        function toggle(): void {
            UiState.overlay = !UiState.overlay;
        }
        function close(): void {
            UiState.overlay = false;
        }
    }

    IpcHandler {
        target: "streamer"
        function toggle(): void {
            Streamer.toggle();
        }
        function active(): bool {
            return Streamer.active;
        }
    }

    IpcHandler {
        target: "dock"
        function pin(appId: string): void {
            Taskbar.pin(appId.toLowerCase());
        }
        function unpin(appId: string): void {
            Taskbar.unpin(appId.toLowerCase());
        }
    }

    IpcHandler {
        target: "brightness"
        function increment(): void {
            Brightness.increment();
        }
        function decrement(): void {
            Brightness.decrement();
        }
        function set(percent: int): void {
            Brightness.set(percent / 100);
        }
    }

    IpcHandler {
        target: "notifications"
        function dnd(): void {
            Notifs.toggleDnd();
        }
        function clear(): void {
            Notifs.clear();
        }
    }

    // The settings app is its own process (`qs -p settings.qml`), alive only while
    // its window is open. A second open raises the running one instead.
    IpcHandler {
        target: "settings"
        function open(): void {
            Session.openSettings("");
        }
        function page(name: string): void {
            Session.openSettings(name);
        }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void {
            Wallpaper.set(path);
        }
        function random(): void {
            Wallpaper.random();
        }
        function pick(): void {
            Wallpaper.pick();
        }
        // dark | light
        function mode(m: string): void {
            Wallpaper.setMode(m);
        }
        // a matugen scheme, e.g. scheme-tonal-spot
        function scheme(name: string): void {
            Config.theme.scheme = name;
            Wallpaper.retheme();
        }
    }
}
