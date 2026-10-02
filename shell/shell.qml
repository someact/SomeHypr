//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
// NVIDIA only: without this glvnd also loads Mesa + LLVM (~100 MB RSS for nothing)
//@ pragma Env __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json

// SomeHypr shell. Run with `qs -c somehypr`.
// One island, two corner pills and a dock per monitor, a wallpaper layer,
// global shortcuts and IPC. Every panel inside the island, the overview, the
// region selector, the game overlay and the private peek are loaded on demand.

import QtQuick
import Quickshell
import qs.services
import "island"
import "corners"
import "wallpaper"
import "dock"
import "overview"
import "capture"
import "overlay"

ShellRoot {
    Variants {
        model: Quickshell.screens
        WallpaperLayer {}
    }
    Variants {
        model: Quickshell.screens
        LeftPill {}
    }
    Variants {
        model: Quickshell.screens
        RightPill {}
    }
    Variants {
        model: Quickshell.screens
        Dock {}
    }
    Variants {
        model: Quickshell.screens
        Island {}
    }

    Overview {}
    RegionSelector {}
    GameOverlay {}
    PrivatePeek {}

    Shortcuts {}
    Ipc {}

    // Services that act on their own (not only when a panel reads them)
    Component.onCompleted: {
        DayNight.check();
        GameClients.pids;
    }
}
