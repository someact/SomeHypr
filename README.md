# SomeHypr

A personal Hyprland desktop for one PC: CachyOS, Hyprland 0.56 (Lua config), NVIDIA RTX 3060, one 1920×1080 @ 100 Hz monitor, US/TH keyboard and a pen tablet.

It has a dynamic island instead of a bar, glass surfaces, spring motion, and colors taken from the wallpaper. Everything is written to stay light: no Python, no polling, and panels load only while open.

- Goals: [`idea.md`](idea.md)
- Plan, phases and progress: [`docs/plan.md`](docs/plan.md)
- Notes for agents working on the repo: [`CLAUDE.md`](CLAUDE.md)

## How it works

The repo has three parts. `install.sh` links each one into `~/.config`, so editing the repo edits the live desktop.

| Repo | Linked to | What it is |
|---|---|---|
| `hypr/` | `~/.config/hypr` | Hyprland config in Lua |
| `shell/` | `~/.config/quickshell/somehypr` | The desktop shell (Quickshell, QML) |
| `matugen/` | `~/.config/matugen` | Wallpaper → color scheme for the shell, Hyprland, terminals, GTK, KDE, Zen, Vesktop |

### Hyprland (`hypr/`)
`hyprland.lua` loads files in a fixed order, and every setting lives in exactly one file:

| File | Holds |
|---|---|
| `user.lua` | your choices (apps, `glass`, `fastGlass`, `liquidGlass`, `gameModeAuto`) |
| `core/` | NVIDIA env, input and tablet, look, motion, misc, autostart, liquid glass |
| `rules/` | window and layer rules |
| `binds/` | every keybind |
| `modes/gamemode.lua` | game mode: turns blur, shadows and animations off while a game is the focused fullscreen window |

The settings app never edits these files. It writes its changes to `~/.config/somehypr/hypr.json` (Hyprland choices) and `~/.config/somehypr/keybinds.json` (keybinds). Those load on top of the repo defaults, so `git pull` never conflicts with your settings.

### Shell (`shell/`)
One Quickshell process, `qs -c somehypr`, started by Hyprland:

| Part | What it does |
|---|---|
| **Island** | The notch at the top. Collapsed, it shows the clock, media, notifications, OSD and recording. Rest the pointer on it (or flick to the screen edge above it) for a peek; click or tap Super to open it fully. Open, it holds search, quick controls, media (with the player's own volume and synced lyrics), notifications, system and power. Quick tiles and the volume, mic and brightness sliders can be shown, hidden and reordered (pencil), and each tile can be full (icon and text) or icon only; and right-clicking one opens its detail page (Wi-Fi, Bluetooth, night light, sound devices) or its settings page; right-click the volume slider for the per-app mixer. |
| **Pills** | Workspaces, app title, tray, status icons and clock. Each one can sit in a top corner or beside the island, in any order, as glass or floating (Settings → Island). Hover the workspaces (or hold Super) to see them all; right-click the network, Bluetooth or volume icon for its page or the mixer. |
| **Dock** | Bottom bar with pinned and running apps. |
| **Super+Tab** | Workspace overview. |
| **Super+G** | Game overlay with resources, mixer, crosshair, FPS limit, notes and lyrics (pin a card to keep it over the game). |
| **Super+K** | On-screen keyboard. |
| **Capture** | Region tools: screenshot, OCR, Lens, translate, live translate (keeps translating an area, e.g. game subtitles, in a pinned overlay card; `/translate live`), record. |
| **Desktop** | Lock screen and desktop widgets: clock, now playing, system, notes, calendar, weather (Open-Meteo), wallpaper, gallery, lyrics, quick launch. Right-click one to arrange them. |
| **Settings** | A separate window: `qs -c somehypr ipc call settings open`, or `/settings` in search. |

- **Glass:** the compositor blurs exactly the shapes the shell draws (`ext-background-effect`). An optional plugin, *liquid glass*, adds refraction on top; see below.
- **Colors:** set a wallpaper (`/wallpaper`, or the island's wallpaper view) and matugen recolors everything. Video wallpapers run through mpvpaper.
- **Time of day:** Settings → Wallpaper → Time of day switches the wallpaper, light/dark colors and night light at sunrise, noon, sunset, night and midnight. Each slot keeps the wallpaper, sets one file, picks at random from a folder, or keeps picking a new one every few minutes (dynamic). Slot times can follow the sun (Open-Meteo, from the weather place or your IP's rough location).
- **Lyrics:** the playing track's lyrics come from [LRCLIB](https://lrclib.net), asked once per track with curl and cached in `~/.cache/somehypr/lyrics/` (misses too). Turn it off in Settings → Island → Lyrics (`media.lyrics`).
- **Shell settings** live in `~/.config/somehypr/config.json`. The file reloads live, so you can edit it by hand too.

## Install

The setup targets this one machine, but these are the pieces it expects:

```sh
# Hyprland 0.56+ and the shell (paru also covers packages that are only in the AUR)
paru -S hyprland quickshell matugen hypridle hyprlock
# tools the shell calls
paru -S grim slurp wl-clipboard cliphist imagemagick jq curl wf-recorder \
        tesseract tesseract-data-eng translate-shell mpvpaper ydotool swappy
# fonts
paru -S ttf-material-symbols-variable-git ttf-jetbrains-mono-nerd
# plus Google Sans Flex (from Google Fonts) in ~/.local/share/fonts
```

> On this machine, Google Sans Flex and the Material Symbols file the shell loads both come from ii's `ii-sddm-theme-fonts` package. Before you remove the `illogical-impulse-*` packages, copy the fonts to `~/.local/share/fonts`, or the shell falls back to other fonts.

Then link everything:

```sh
git clone https://github.com/someact/SomeHypr && cd SomeHypr
./install.sh            # links hypr/, shell/, matugen/ into ~/.config and reloads Hyprland
```

`install.sh` moves any existing directory it replaces to `<name>.pre-somehypr`. If the new config has errors after the reload, it rolls back by itself.

```sh
./install.sh --check     # only verify the Hyprland config, change nothing
./install.sh --rollback  # remove the links and restore the .pre-somehypr directories
```

## Update

```sh
git pull
./install.sh --check && hyprctl reload   # Hyprland part
```

- **Shell:** files under `shell/` reload the running shell as soon as they change, so a pull is live at once. If something looks stuck, restart it with `pkill -x qs; qs -c somehypr &`.
- **After a Hyprland update:** rebuild the liquid glass plugin if you use it (see below). Until you rebuild it, it simply isn't loaded.
- **After a Quickshell update:** restart the shell.

## Liquid glass (optional)

[hyprglass](https://github.com/hyprnux/hyprglass) adds refraction and an edge light to the island, pills, dock and keyboard. It is off by default. It is built from source, because a plugin only works with the exact Hyprland build it was compiled for:

```sh
~/.config/hypr/scripts/hyprglass.sh             # build for the running Hyprland
~/.config/hypr/scripts/hyprglass.sh --rebuild   # after a Hyprland update
```

The script checks out upstream's `hyprland-<x.y>` branch and applies `hypr/plugins/hyprglass-fit-shape.patch`, which makes the glass follow the shell's rounded shapes. It installs `~/.local/share/somehypr/plugins/hyprglass-<version>.so`.

To turn it on, use Settings → Appearance → Liquid glass, which also has a Build button, or set `liquidGlass = true` in `hypr/user.lua`. On the RTX 3060 it showed no measurable GPU or CPU cost and used about 40 MB more VRAM.

With glass windows on, Settings → Appearance → Fast glass (`fastGlass` in `hypr/user.lua`) makes window blur sample only the wallpaper, so Hyprland can cache it. Tiled windows look the same; a floating glass window over another window shows the wallpaper behind it instead of that window. On the RTX 3060 it made no measurable difference; it is meant for weaker GPUs.

## Checks

```sh
./install.sh --check                            # config verifies
hyprctl reload && hyprctl configerrors          # must print nothing
hyprctl binds -j | jq length                    # 201 with no custom keybinds
timeout 10 qs -p shell/shell.qml 2>&1 | grep -E "WARN|ERROR"
```

`CLAUDE.md` has the full list, including the IPC calls that open each part of the shell.

To measure the shell and Hyprland, run `hypr/scripts/bench.sh`. It prints the shell's memory (anonymous memory and PSS are the numbers to compare, against a fresh start) and its font mappings, then CPU for the shell and Hyprland, plus GPU use and power on NVIDIA, over 30 s. `--cycle N` opens every island view, the overview, the game overlay and widget edit mode N times and prints memory after each round.
