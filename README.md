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
| `core/` | NVIDIA env, input (keyboard, touchpad and gestures, tablet), look, motion, misc, autostart, liquid glass |
| `rules/` | window and layer rules |
| `binds/` | every keybind |
| `modes/gamemode.lua` | game mode: turns blur, shadows and animations off while a game is the focused fullscreen window |

Screens: `generated/monitors.lua` (written by Settings → Displays, per machine and gitignored) names your outputs; any output it doesn't name runs at its fastest mode. A machine that has never saved displays falls back to the tracked `monitors.lua`.

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
| **Laptops** | Found at start, so a desktop shows none of it. The status pill shows the battery (icon and percent, red at 15% on battery). Right-click it for Settings → Power, which has **battery bypass**: UPower's charge limit, which on Lenovo IdeaPad/Legion is conservation mode (stops near 80%, runs from the charger). It's also a quick tile, and switching it needs no password. Brightness keys and the slider drive the panel backlight (brightnessctl); external monitors still use DDC. Settings → Hyprland → Touchpad (shown only with a touchpad) sets natural scrolling, tap to click, finger clicks, typing lockout, scroll speed and gestures: 4 fingers sideways switches workspace, up or down opens the overview; 3 fingers drag a window or pinch for fullscreen. |
| **Settings** | A separate window: `qs -c somehypr ipc call settings open`, or `/settings` in search. |

- **Glass:** the compositor blurs exactly the shapes the shell draws (`ext-background-effect`). An optional plugin, *liquid glass*, adds refraction on top; see below.
- **Colors:** set a wallpaper (`/wallpaper`, or the island's wallpaper view) and matugen recolors everything. Video wallpapers run through mpvpaper.
- **Time of day:** Settings → Wallpaper → Time of day switches the wallpaper, light/dark colors and night light at sunrise, noon, sunset, night and midnight. Each slot keeps the wallpaper, sets one file, picks at random from a folder, or keeps picking a new one every few minutes (dynamic). Slot times can follow the sun (Open-Meteo, from the weather place or your IP's rough location).
- **Lyrics:** the playing track's lyrics come from [LRCLIB](https://lrclib.net), asked once per track with curl and cached in `~/.cache/somehypr/lyrics/` (misses too). Turn it off in Settings → Island → Lyrics (`media.lyrics`).
- **Shell settings** live in `~/.config/somehypr/config.json`. The file reloads live, so you can edit it by hand too.

## Install

On Arch or CachyOS with Hyprland 0.56+ (Lua config):

```sh
git clone https://github.com/someact/SomeHypr && cd SomeHypr
./install.sh                      # asks before each change; -y answers yes to all
```

`install.sh` works out what this machine needs and asks before it changes anything:

1. **Packages:** installs whatever is missing with pacman, or paru/yay for AUR packages: Hyprland, Quickshell, matugen, hypridle/hyprlock, capture and OCR tools, mpvpaper, ydotool, ddcutil, plus upower and power-profiles-daemon on a laptop. Fonts are Material Symbols, JetBrains Mono Nerd and the Bibata cursor. Google Sans Flex isn't packaged, so it's downloaded from google/fonts (OFL) into `~/.local/share/fonts/somehypr`.
2. **Services:** enables the ydotool user service (on-screen keyboard). For DDC brightness on external monitors, it loads i2c-dev at boot and adds you to the `i2c` group.
3. **Links:** links `hypr/`, `shell/`, `matugen/` into `~/.config`. Any directory it replaces is moved to `<name>.pre-somehypr`.
4. **Screens:** inside Hyprland, it writes `hypr/generated/monitors.lua` from the connected monitors. Each gets its largest resolution and fastest refresh, a scale from its pixel density (unless you already set one), and a left-to-right layout. An existing file is kept. From a TTY, every screen gets its fastest mode until you run `--detect`.
5. **Session:** reloads Hyprland and rolls back if there are config errors. It then stops any other Quickshell config (e.g. ii) and starts the SomeHypr shell, so a running session switches over without logging out.

Hardware is also detected at runtime, so one config fits every machine. The NVIDIA env is set only when NVIDIA is the only GPU. Battery, backlight and touchpad features appear only when that hardware exists.

```sh
./install.sh --update            # git pull, then the same setup (only what is missing)
./install.sh --detect            # redo the screen setup after changing monitors
./install.sh --wallpaper <file>  # also set a wallpaper; matugen colors everything from it
./install.sh --no-deps           # skip packages and fonts
./install.sh --check             # only verify the Hyprland config, change nothing
./install.sh --rollback          # remove the links and restore the .pre-somehypr directories
```

Every step is safe to run again. Without a terminal and without `-y`, every question is answered no, so nothing is installed unattended.

## Update

```sh
./install.sh --update   # or: git pull && ./install.sh --check && hyprctl reload
```

- **Shell:** files under `shell/` reload the running shell as soon as they change, so a pull is live at once. If something looks stuck, restart it with `pkill -x qs; qs -c somehypr &`.
- **After a Hyprland update:** rebuild the liquid glass plugin if you use it (see below). Until you rebuild it, it simply isn't loaded.
- **After a Quickshell update:** restart the shell.
- **After a Qt update:** restart the shell to load the updated image plugins. If Quickshell warns that it was built against a different Qt version, it also needs a matching package rebuild. Application icons support both theme names and absolute image paths from desktop files.

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
