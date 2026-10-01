-- Game mode: while a game is the focused fullscreen window, turn off blur,
-- shadows and animations so the compositor does as little work as possible.
-- Everything is restored as soon as focus leaves the game or it exits fullscreen.
--
-- Runs inside Hyprland (no extra process). Manual control from anywhere:
--   hyprctl eval 'GameMode.toggle()'   force on/off
--   hyprctl eval 'GameMode.auto()'     back to automatic
--   hyprctl repl 'return GameMode.active'

GameMode = { active = false, forced = nil }

local function is_game(w)
    if w == nil or (w.fullscreen or 0) < 2 then return false end
    if matches_any(w.class, NOT_GAME_CLASS_PATTERNS) then return false end
    return w.content_type == "game"
        or matches_any(w.class, GAME_CLASS_PATTERNS)
        or matches_any(w.title, GAME_TITLE_PATTERNS)
end

local function apply(on)
    if on == GameMode.active then return end
    GameMode.active = on
    if on then
        hl.config({
            decoration = { blur = { enabled = false }, shadow = { enabled = false } },
            animations = { enabled = false },
        })
    else
        hl.config({
            decoration = { blur = { enabled = look.blur.enabled }, shadow = { enabled = look.shadow.enabled } },
            animations = { enabled = true },
        })
    end
end

local function evaluate()
    if GameMode.forced ~= nil then
        apply(GameMode.forced)
    elseif gameModeAuto then
        apply(is_game(hl.get_active_window()))
    end
end

function GameMode.toggle()
    GameMode.forced = not GameMode.active
    evaluate()
    return GameMode.active
end

function GameMode.auto()
    GameMode.forced = nil
    evaluate()
    return GameMode.active
end

for _, event in ipairs({ "window.fullscreen", "window.active", "window.destroy", "workspace.active" }) do
    hl.on(event, evaluate)
end
hl.on("config.reloaded", evaluate)
