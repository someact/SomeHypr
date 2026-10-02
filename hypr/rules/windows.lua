-- General window rules: dialogs, utilities, glass.
-- App-specific rules live in gaming.lua, art.lua and media.lua.

-- Blur breaks xwayland context menus (no class, no title)
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })

-- File pickers and "save" prompts float in the middle
for _, title in ipairs({
    "^(Open File)(.*)$", "^(Select a File)(.*)$", "^(Open Folder)(.*)$", "^(Save As)(.*)$",
    "^(Library)(.*)$", "^(File Upload)(.*)$", "^(.*)(wants to save)$", "^(.*)(wants to open)$",
    "^(Choose wallpaper)(.*)$",
}) do
    hl.window_rule({ match = { title = title }, float = true, center = true })
end
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, size = { "(monitor_w*0.60)", "(monitor_h*0.65)" } })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true, size = { "(monitor_w*0.60)", "(monitor_h*0.65)" } })

-- Small utility windows
for _, class in ipairs({ "^(pavucontrol)$", "^(org.pulseaudio.pavucontrol)$", "^(nm-connection-editor)$", "^(Zotero)$" }) do
    hl.window_rule({ match = { class = class }, float = true, center = true, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
end
for _, class in ipairs({ "^(blueberry\\.py)$", ".*plasmawindowed.*", "kcm_.*", ".*bluedevilwizard" }) do
    hl.window_rule({ match = { class = class }, float = true })
end

-- Shell windows (ii settings/welcome, new shell settings)
for _, title in ipairs({ ".*Welcome", "^(illogical-impulse Settings)$", ".*Shell conflicts.*", "^(SomeHypr Settings)$" }) do
    hl.window_rule({ match = { title = title }, float = true })
end

hl.window_rule({ match = { title = "^(SomeHypr Settings)$" }, center = true, size = { 1080, 740 } })

-- kde-material-you-colors flashes a window when switching dark/light: hide it off-screen
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, float = true, no_initial_focus = true, move = { 999999, 999999 } })

-- Dolphin's copy progress window
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = { 40, 80 } })

hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Only floating windows cast shadows
hl.window_rule({ match = { float = 0 }, no_shadow = true })

-- Scratchpad (SUPER+S) floats in from the edges with a wider margin
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- Glass
if glass then
    hl.window_rule({ match = { class = "^(kitty|Alacritty|foot)$" }, opacity = "0.88 override 0.80 override" })
    hl.window_rule({ match = { class = "^(discord|vesktop|spotify)$" }, opacity = "0.90 override 0.84 override" })
    hl.window_rule({ match = { class = "^(org.kde.dolphin|dolphin|antigravity|code|Code)$" }, opacity = "0.92 override 0.88 override" })
    -- Zen draws its own translucency (Transparent Zen mod); the compositor blurs behind it
else
    -- Opaque windows: skip blur entirely, it would be invisible anyway
    hl.window_rule({ match = { class = ".*" }, no_blur = true })
end
