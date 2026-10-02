-- Layer surfaces: shell panels, launchers, pickers.

-- Blur on layers samples only the wallpaper: cheaper and steady while windows move
hl.layer_rule({ match = { namespace = ".*" }, xray = true })

-- Instant tools
for _, ns in ipairs({ "selection", "hyprpicker", "noanim", "gtk4-layer-shell" }) do
    hl.layer_rule({ match = { namespace = ns }, no_anim = true })
end

-- CLI fallbacks used when the shell is not running (fuzzel, wlogout)
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

if shell == "ii" then
    hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true, blur_popups = true, ignore_alpha = 0.79 })
    hl.layer_rule({ match = { namespace = "quickshell:bar" }, animation = "slide" })
    hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, animation = "slide" })
    hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" }, animation = "slide" })
    hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" }, animation = "slide bottom" })
    hl.layer_rule({ match = { namespace = "quickshell:dock" }, animation = "slide bottom" })
    hl.layer_rule({ match = { namespace = "quickshell:osk" }, animation = "slide bottom", order = -1 })
    hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, animation = "slide right" })
    hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, animation = "slide left" })
    hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "slide top" })
    hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%" })
    hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade" })
    for _, ns in ipairs({
        "actionCenter", "lockWindowPusher", "overlay", "overview", "polkit", "regionSelector",
        "screenshot", "session", "wNotificationCenter", "wOnScreenDisplay", "wStartMenu", "wTaskView",
    }) do
        hl.layer_rule({ match = { namespace = "quickshell:" .. ns }, no_anim = true })
    end
    -- Tooltips and media popup: no blur bleed through their rounded edges
    hl.layer_rule({ match = { namespace = "quickshell:popup" }, xray = false, ignore_alpha = 1 })
    hl.layer_rule({ match = { namespace = "quickshell:overlay" }, ignore_alpha = 1 })
    hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1 })
    hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true, ignore_alpha = 0 })
    hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, ignore_alpha = 0 })
end

if shell == "somehypr" then
    -- The shell animates its own surfaces (springs), and blurs exactly the
    -- notch/pill shapes itself through ext-background-effect, so no layer blur here.
    for _, ns in ipairs({ "somehypr:island", "somehypr:pill", "somehypr:wallpaper", "somehypr:dock", "somehypr:overview" }) do
        hl.layer_rule({ match = { namespace = ns }, no_anim = true })
    end
end
