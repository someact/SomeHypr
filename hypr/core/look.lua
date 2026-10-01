-- Gaps, borders, rounding, blur, shadows, dim.
-- This is the only file that sets these. Values are what your ii setup actually
-- ended up using after all its overrides. Border colors come from generated/colors.lua.

-- Kept in a table so modes/gamemode.lua can turn effects off and restore them.
look = {
    blur = {
        enabled = true,
        xray = false,
        special = false,
        new_optimizations = true,
        size = 1,
        passes = 3,
        brightness = 1,
        noise = 0.03,
        contrast = 0.9,
        vibrancy = 0.3,
        vibrancy_darkness = 0.3,
        popups = false,
        popups_ignorealpha = 0.6,
        input_methods = true,
        input_methods_ignorealpha = 0.8,
    },
    shadow = {
        enabled = true,
        range = 20,
        offset = { 0, 2 },
        render_power = 10,
        color = "rgba(00000020)",
    },
}

if glass then
    -- Stronger frost so translucent windows read as glass, not as see-through
    look.blur.size = 6
    look.blur.passes = 2
end

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 5,
        gaps_workspaces = 50,
        border_size = 1,
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true, -- lets the `immediate` rules in rules/gaming.lua work
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true,
        },
    },
    decoration = {
        rounding = 22,
        rounding_power = 2.5,
        active_opacity = 1,
        inactive_opacity = 1,
        blur = look.blur,
        shadow = look.shadow,
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.2,
    },
})
