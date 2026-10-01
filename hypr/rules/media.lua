-- Video, images, streaming and screen sharing.

-- Picture-in-picture: small, pinned, bottom-right, aspect locked
local pip = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
hl.window_rule({
    match = { title = pip },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    move = { "(monitor_w*0.73)", "(monitor_h*0.72)" },
    size = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
    opaque = true,
    no_blur = true,
})

-- Video players, image viewers, OBS and meetings: always solid, never blurred
for _, class in ipairs({
    "^(mpv|vlc|org\\.videolan\\.vlc|io\\.github\\.celluloid_player\\.Celluloid)$",
    "^(imv|swappy|feh|loupe|eog|gwenview|org\\.kde\\.gwenview)$",
    "^(obs|com\\.obsproject\\.Studio|zoom)$",
    "^(brave-browser|brave-origin|firefox|chromium|google-chrome)$",
}) do
    hl.window_rule({ match = { class = class }, opaque = true, no_blur = true })
end

-- "X is sharing your screen" bar: pinned at the bottom centre
hl.window_rule({
    match = { title = ".*is sharing (a window|your screen).*" },
    float = true,
    pin = true,
    move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})
