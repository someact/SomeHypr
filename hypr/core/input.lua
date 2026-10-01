-- Keyboard, mouse and pen tablet.

hl.config({
    input = {
        -- US + Thai, SUPER+Space switches
        kb_layout = "us,th",
        kb_options = "grp:win_space_toggle",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,

        follow_mouse = 1,
        off_window_axis_events = 2,
    },
})

-- UGTablet 10" pen (254 x 158.75 mm, 16:10) on the 16:9 monitor.
-- The active area is trimmed to 254 x 142.9 mm and centred vertically so the
-- pen keeps the screen's aspect ratio: circles stay circles in Clip Studio and Krita.
hl.device({
    name = "ugtablet-10-inch-pentablet-pen",
    output = "DP-1",
    active_area_size = { 254, 142.9 },
    active_area_position = { 0, 7.9 },
})
