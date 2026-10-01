-- User choices. Hand-edited for now; the settings app (Phase 5) will own these.

-- Which Quickshell config draws the desktop: "ii" (end-4, current) or
-- "somehypr" (the new shell, from Phase 2). Changing this switches every
-- shell keybind, the autostart entry and the lock screen together.
shell = "ii"

-- Apps
local pick = HYPR_DIR .. "/scripts/launch_first_available.sh"
terminal       = "kitty -1"
fileManager    = "dolphin"
browser        = "zen-browser"
codeEditor     = "antigravity"
textEditor     = pick .. " 'kate' 'gnome-text-editor' 'emacs'"
officeSoftware = pick .. " 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
volumeMixer    = pick .. " 'pavucontrol-qt' 'pavucontrol'"
taskManager    = "kitty -1 btop"

-- SUPER+1..0 address workspaces inside groups of this size.
workspaceGroupSize = 10

-- Glass: translucent terminals, chat and editors with frosted blur.
-- false = every window opaque, blur only on shell surfaces (your current look).
glass = false

-- Game mode: turn off blur, shadows and animations while a game is fullscreen.
gameModeAuto = true
