import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.core
import qs.services
import qs.commands

// Global shortcuts under appid "somehypr". hypr/binds/shell.lua maps keys to
// these names, so the keybinds stay identical when switching shells.
Scope {
    id: root

    component Shortcut: GlobalShortcut {
        appid: "somehypr"
    }

    // Super tap opens search. A tap is a press and release of Super alone,
    // shorter than 400 ms, with no workspace/window change in between
    // (Super+1, Super+arrows...).
    property real superPressedAt: 0
    Shortcut {
        name: "searchToggleRelease"
        description: "Toggle search on Super release"
        onPressed: {
            UiState.superMightTrigger = true;
            root.superPressedAt = Date.now();
        }
        onReleased: {
            const tap = UiState.superMightTrigger && Date.now() - root.superPressedAt < 400;
            UiState.superMightTrigger = false;
            if (tap)
                UiState.toggle("search");
        }
    }
    Shortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Cancel the pending Super tap"
        onPressed: UiState.superMightTrigger = false
    }
    Connections {
        target: Hyprland
        enabled: UiState.superMightTrigger
        function onRawEvent(event) {
            if (["workspace", "workspacev2", "activewindow", "activewindowv2", "movewindow", "movewindowv2", "openwindow", "closewindow", "fullscreen", "changefloatingmode"].includes(event.name))
                UiState.superMightTrigger = false;
        }
    }

    // Super held: the left pill shows workspace numbers
    Shortcut {
        name: "superKey"
        description: "Super key held"
        onPressed: UiState.superHeld = true
        onReleased: UiState.superHeld = false
    }

    Shortcut {
        name: "clipboardToggle"
        description: "Clipboard history"
        onPressed: UiState.toggle("clipboard")
    }
    Shortcut {
        name: "emojiToggle"
        description: "Emoji picker"
        onPressed: UiState.toggle("emoji")
    }
    Shortcut {
        name: "controlToggle"
        description: "Quick controls"
        onPressed: UiState.toggle("control")
    }
    Shortcut {
        name: "mediaToggle"
        description: "Media controls"
        onPressed: UiState.toggle("media")
    }
    Shortcut {
        name: "keysToggle"
        description: "Keyboard shortcuts"
        onPressed: UiState.toggle("keys")
    }
    Shortcut {
        name: "powerToggle"
        description: "Session menu"
        onPressed: UiState.toggle("power")
    }
    Shortcut {
        name: "islandHideToggle"
        description: "Hide the island and corner pills"
        onPressed: UiState.hidden = !UiState.hidden
    }
    Shortcut {
        name: "wallpaperToggle"
        description: "Change wallpaper"
        onPressed: UiState.open("search", "/wallpaper ")
    }
    Shortcut {
        name: "wallpaperRandom"
        description: "Random wallpaper"
        onPressed: Wallpaper.random()
    }
    // Region tools run the CLI tools until the Phase 6 UI exists
    Shortcut {
        name: "regionScreenshot"
        description: "Screenshot a region"
        onPressed: Commands.run("shot")
    }
    Shortcut {
        name: "regionOcr"
        description: "Copy text from a region"
        onPressed: Commands.run("ocr")
    }
    Shortcut {
        name: "regionRecord"
        description: "Record a region"
        onPressed: Commands.run("record")
    }
    Shortcut {
        name: "regionSearch"
        description: "Search a region with Google Lens"
        onPressed: Quickshell.execDetached(["sh", "-c", "pidof slurp || " + Paths.scripts + "/snip_to_search.sh"])
    }

    Shortcut {
        name: "toggleLightDark"
        description: "Toggle light/dark colors"
        onPressed: Wallpaper.toggleLightDark()
    }
}
