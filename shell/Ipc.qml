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

    IpcHandler {
        target: "settings"
        function open(): void {
            Quickshell.execDetached(["xdg-open", Paths.config]);
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
    }
}
