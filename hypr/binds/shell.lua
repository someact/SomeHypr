-- Shell actions, resolved for whichever shell `user.lua` selects.
--
-- Each action names the global shortcut the shell registers (ii under appid
-- "quickshell", the new shell under "somehypr") and an optional CLI fallback
-- that runs only while the shell is not running. An action whose shell entry
-- is nil always runs its fallback (used while the new shell lacks a feature).

local scripts = HYPR_DIR .. "/scripts"
local iiScripts = HOME .. "/.config/quickshell/ii/scripts"

local ocr = "grim -g \"$(slurp $SLURP_ARGS)\" /tmp/ocr_image.png && "
    .. "tesseract /tmp/ocr_image.png stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | paste -sd+) | wl-copy; "
    .. "rm -f /tmp/ocr_image.png"

local appid = { ii = "quickshell", somehypr = "somehypr" }

SHELL_ACTIONS = {
    search           = { ii = "searchToggleRelease",      somehypr = "searchToggleRelease", fallback = "pkill fuzzel || fuzzel" },
    superKey         = { ii = "workspaceNumber",          somehypr = "superKey" },
    overview         = { ii = "overviewWorkspacesToggle", somehypr = "overviewToggle" },
    clipboard        = { ii = "overviewClipboardToggle",  somehypr = "clipboardToggle",
                         fallback = "pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy" },
    emoji            = { ii = "overviewEmojiToggle",      somehypr = "emojiToggle", fallback = "pkill fuzzel || " .. scripts .. "/fuzzel-emoji.sh copy" },
    sidebar          = { ii = "sidebarRightToggle",       somehypr = "controlToggle" },
    cheatsheet       = { ii = "cheatsheetToggle",         somehypr = "keysToggle" },
    osk              = { ii = "oskToggle",                somehypr = "oskToggle" },
    media            = { ii = "mediaControlsToggle",      somehypr = "mediaToggle" },
    overlay          = { ii = "overlayToggle",            somehypr = "overlayToggle" },
    session          = { ii = "sessionToggle",            somehypr = "powerToggle", fallback = "pkill wlogout || wlogout -p layer-shell" },
    bar              = { ii = "barToggle",                somehypr = "islandHideToggle" },
    wallpaper        = { ii = "wallpaperSelectorToggle",  somehypr = "wallpaperToggle", fallback = iiScripts .. "/colors/switchwall.sh" },
    wallpaperRandom  = { ii = "wallpaperSelectorRandom",  somehypr = "wallpaperRandom" },
    lightDark        = { ii = "toggleLightDark",          somehypr = "toggleLightDark" },
    panelFamily      = { ii = "panelFamilyCycle" },
    regionScreenshot = { ii = "regionScreenshot",         somehypr = "regionScreenshot",
                         fallback = "pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent" },
    regionSearch     = { ii = "regionSearch",             somehypr = "regionSearch", fallback = "pidof slurp || " .. scripts .. "/snip_to_search.sh" },
    regionOcr        = { ii = "regionOcr",                somehypr = "regionOcr", fallback = "pidof slurp || " .. ocr },
    screenTranslate  = { ii = "screenTranslate",          somehypr = "screenTranslate" },
    regionRecord     = { ii = "regionRecord",             somehypr = "regionRecord", fallback = scripts .. "/record.sh" },
}

-- Shell-specific commands that are not global shortcuts
SHELL_COMMANDS = {
    ii = {
        restart  = "killall ydotool qs quickshell; qs -c ii &",
        settings = "XDG_CURRENT_DESKTOP=gnome qs -p ~/.config/quickshell/ii/settings.qml",
        welcome  = "qs -p ~/.config/quickshell/ii/welcome.qml",
    },
    somehypr = {
        restart  = "killall qs quickshell; qs -c somehypr &",
        settings = "qs -c somehypr ipc call settings open",
    },
}

local isAlive = "qs -c " .. shell .. " ipc call TEST_ALIVE"

-- Bind `keys` to a shell action. `opts` are normal hl.bind options; the
-- description is attached only to the first bind so cheatsheets list it once.
function shell_bind(keys, action, opts)
    local a = SHELL_ACTIONS[action]
    assert(a, "unknown shell action: " .. action)
    opts = opts or {}
    local name = a[shell]
    if name then
        hl.bind(keys, hl.dsp.global(appid[shell] .. ":" .. name), opts)
        if a.fallback then
            local quiet = {}
            for k, v in pairs(opts) do
                if k ~= "description" then quiet[k] = v end
            end
            hl.bind(keys, hl.dsp.exec_cmd(isAlive .. " || " .. a.fallback), quiet)
        end
    elseif a.fallback then
        hl.bind(keys, hl.dsp.exec_cmd(a.fallback), opts)
    end
end

function shell_command(name)
    return SHELL_COMMANDS[shell][name]
end
