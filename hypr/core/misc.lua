-- Layout, misc behaviour, render and cursor settings.

-- Fallback for any monitor not listed in monitors.lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        -- Adaptive sync only for fullscreen apps (games). The desktop stays at a
        -- fixed 100 Hz so cursor and animations never judder.
        vrr = 2,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = true,
    },

    render = {
        -- Scan out fullscreen games directly (skips compositing) only when the
        -- app says its content type is "game", which avoids NVIDIA glitches elsewhere.
        direct_scanout = 2,
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true,
    },

    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})
