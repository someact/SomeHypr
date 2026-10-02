-- User choices: the defaults below, overridden by the settings app (hypr.json,
-- see the end of this file).

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

-- Settings app overrides (Appearance, Modes and Apps pages)
glass = setting("glass", glass)
gameModeAuto = setting("gameModeAuto", gameModeAuto)
for _, name in ipairs({ "terminal", "fileManager", "browser", "codeEditor", "textEditor", "officeSoftware", "volumeMixer", "taskManager" }) do
    _G[name] = setting("apps." .. name, _G[name])
end
