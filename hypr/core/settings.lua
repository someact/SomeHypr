-- Hyprland options changed in the settings app (hypr.json "hyprland": a partial
-- hl.config table). Loaded last so it wins over core/*; it only holds keys the
-- settings page writes, so untouched options keep the values in core/.

local opts = SETTINGS.hyprland
if type(opts) ~= "table" or next(opts) == nil then return end

hl.config(opts)

-- Game mode restores effects from `look` when a game exits; keep it in sync
local d = opts.decoration or {}
if type(d.blur) == "table" and d.blur.enabled ~= nil then look.blur.enabled = d.blur.enabled end
if type(d.shadow) == "table" and d.shadow.enabled ~= nil then look.shadow.enabled = d.shadow.enabled end
if type(opts.animations) == "table" and opts.animations.enabled ~= nil then look.animations = opts.animations.enabled end
