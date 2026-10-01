-- Animation curves. Things that appear or move use springs (they settle
-- naturally instead of running a fixed timeline); things that leave use a
-- short accelerating bezier so dismissals feel instant.
--
-- Spring presets are derived from Apple's response/damping model (mass 1):
--   stiffness = (2*pi / response)^2,  dampening = 4*pi * damping_ratio / response
-- shell/core/Motion.qml (Phase 2) uses the same four presets, so windows and
-- shell surfaces move with one language.
--   smooth  response 0.40  damping 1.00  no bounce: layout, workspaces
--   snappy  response 0.35  damping 0.85  slight settle: windows/layers opening
--   bouncy  response 0.45  damping 0.70  playful: reserved for small elements
--   gentle  response 0.60  damping 1.00  slow and soft: large crossfades
hl.curve("smooth", { type = "spring", mass = 1, stiffness = 246.74, dampening = 31.42 })
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 322.27, dampening = 30.52 })
hl.curve("bouncy", { type = "spring", mass = 1, stiffness = 194.96, dampening = 19.55 })
hl.curve("gentle", { type = "spring", mass = 1, stiffness = 109.66, dampening = 20.94 })

hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("standardDecel",   { type = "bezier", points = { { 0, 0 }, { 0, 1 } } })
hl.curve("menuDecel",       { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menuAccel",       { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } })
hl.curve("stall",           { type = "bezier", points = { { 1, -0.1 }, { 0.7, 0.85 } } })

hl.config({ animations = { enabled = true } })

-- Windows
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.5, spring = "snappy", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2,   bezier = "emphasizedAccel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, spring = "smooth", style = "slide" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 3,   bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 2,   bezier = "emphasizedDecel" })
hl.animation({ leaf = "border",      enabled = true, speed = 10,  bezier = "emphasizedDecel" })

-- Layers (shell surfaces, launchers)
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   spring = "snappy", style = "popin 93%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2.4, bezier = "menuAccel", style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 0.5, bezier = "menuDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.7, bezier = "stall" })

-- Workspaces
hl.animation({ leaf = "workspaces",          enabled = true, speed = 5,   spring = "smooth", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 4,   spring = "snappy", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slidevert" })

-- Cursor zoom (SUPER+Minus / SUPER+Equal)
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "standardDecel" })
