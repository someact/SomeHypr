-- Games: tearing allowed (lowest latency), no effects, flagged as "game" content
-- so direct scanout (render.direct_scanout = 2) and VRR can kick in.

local gameRule = { immediate = true, no_anim = true, no_blur = true, no_shadow = true, content = "game", idle_inhibit = "fullscreen" }

local function game(match)
    local rule = { match = match }
    for k, v in pairs(gameRule) do rule[k] = v end
    hl.window_rule(rule)
end

game({ class = "^(steam_app_).*" })                -- Steam (Proton and native)
game({ class = "^(gamescope)$" })                  -- Steam/Lutris games inside gamescope
-- TwinTail launcher titles (Wine): Genshin, Star Rail, ZZZ, Wuthering Waves, HI3
game({ class = "^(genshinimpact\\.exe|starrail\\.exe|zenlesszonezero\\.exe|client-win64-shipping\\.exe|bh3\\.exe)$" })
game({ title = "^(Minecraft).*" })                 -- Prism Launcher
game({ class = "^(Minecraft).*" })
game({ class = "^(sober|org\\.vinegarhq\\.Sober)$" }) -- Roblox (Sober)
-- Other Wine/Lutris games: window title ends in .exe
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })

-- Same list as Lua patterns, for modes/gamemode.lua (lowercase, matched with string.find)
GAME_CLASS_PATTERNS = {
    "^steam_app_", "^gamescope$",
    "^genshinimpact%.exe$", "^starrail%.exe$", "^zenlesszonezero%.exe$", "^client%-win64%-shipping%.exe$", "^bh3%.exe$",
    "^minecraft", "^sober$", "^org%.vinegarhq%.sober$",
}
GAME_TITLE_PATTERNS = { "^minecraft", "%.exe$" }
-- Never treated as games even when fullscreen
NOT_GAME_CLASS_PATTERNS = { "clipstudio", "blender", "krita" }
