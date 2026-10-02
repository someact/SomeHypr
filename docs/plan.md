# SomeHypr: plan for a personal Hyprland desktop

## Context
The user runs Hyprland 0.56.2 (Lua config) on CachyOS (Ryzen 5 5600, RTX 3060, 15 GiB RAM, one 1080p 100 Hz monitor) with a customized end-4 "illogical-impulse" (ii) Quickshell shell. They like ii's look but find it bloated. `idea.md` asks for:
- smooth, Apple-like motion
- low resource use
- a dynamic-island "everything dock" driven by the Super key
- a bottom app dock
- a GUI settings app, including keybinds
- wallpaper and live wallpaper with auto colors
- desktop widgets and a lock screen
- tuning for gaming, art, coding and streaming

**User decisions:**
- Write a **new Quickshell shell from scratch**, porting proven pieces from ii.
- **Notch** is the default island style. Floating and satellite styles become settings later.
- **MVP = island + Super search.**
- Keep the current keyboard shortcuts.
- Rebuild these ii features later: **Overview (Super+Tab)**, **Region tools UI**, **Game overlay (Super+G)**, **Cheatsheet + OSK**.

## Baseline findings
**Cost of ii today**
- `qs -c ii` uses about 700 MB RSS (1.05 GB peak). Hyprland uses 743 MB.
- Plasma leftovers kded6 and kactivitymanagerd add about 150 MB.
- ii's venv takes 331 MB on disk.

**ii hotspots the new shell must not repeat** (paths under `~/.config/quickshell/ii/`)

| File | Problem |
|---|---|
| `services/HyprlandData.qml:86-94` | Spawns 5 `hyprctl` processes on every Hyprland event, including every window-title change |
| `modules/common/widgets/RippleButton.qml:144-151` | `layer.enabled` + Qt5Compat `OpacityMask` gives each button its own offscreen buffer (about 69 users) |
| `services/Network.qml:156-170` | Every `nmcli monitor` line spawns about 4 more shell processes |
| `Config.qml:514` (`keepRightSidebarLoaded: true`) | The whole sidebar stays in memory |
| `ResourceUsage.qml`, `DateTime.qml` | 3 s timers that always run |
| `Background.qml:201` | Lock screen blur is a GaussianBlur with radius 100 and 201 samples |
| switchwall pipeline | Two color generators: matugen plus Python `generate_colors_material.py` / `applycolor.sh` |
| Notifications, `HyprlandXkb.qml:113` | Rewrite a whole JSON file on every event |

**Quickshell version**
- Was **Quickshell 0.2.1** (pinned by `illogical-impulse-quickshell-git`); upgraded to **0.3.1** in Phase 0.
- `quickshell 0.3.1` is available in `cachyos-extra-v3`. It brings:
  - Networking and Bluetooth services, and a Polkit agent
  - idle monitor and idle inhibitor
  - **`BackgroundEffect.blurRegion`** (ext-background-effect-v1): compositor glass clipped exactly to a shape
  - per-corner `Region` radius
  - `PwNodePeakMonitor`, a visualizer without cava
  - Hyprland Lua support
- Hyprland 0.56 also has **spring** curves.

**Hyprland config**
- Lua files load in this order: `hyprland/*` → `custom/*` → `monitors.lua` → `shellOverrides/main.lua`. The last file overrides blur, rounding and gaps, so the earlier settings fight it.
- 191 binds.
- No NVIDIA env vars.

**Bugs to leave behind**
- hyprlock calls scripts that don't exist.
- SUPER+ALT+N doesn't work on the Thai layout.
- Dead ags/walker layer rules.
- `easyeffects` is autostarted but not installed.
- `monitors.conf` and `workspaces.conf` are dead files.
- `ThumbnailImage.qml:46` uses an undefined `src`.

**Keep**
- All keybinds.
- The Clip Studio rules, including the warning not to add `no_focus` (`~/.config/hypr/custom/rules.lua:3-14`).
- The gamescope and `immediate` tearing rules.
- The matugen templates in `~/.config/matugen`.
- The Transparent Zen mod.
- hypridle timings: 5 / 10 / 15 min.

**Hardware**
- UGTablet 10" pen tablet, with no config yet.
- Keyboard layouts `us, th` (SUPER+Space).

## Targets (audited in Phase 8)
- Shell idle RSS **≤ 250 MB**. About 0% CPU when idle, with no timer under 1 s unless something is visible.
- None of these: Python, cava, nmcli polling, or a separate polkit agent.
- Every animation can be interrupted and retargeted, running at 100 fps.
- A fullscreen game or gamemode makes the desktop overhead near zero.

## Architecture

### Repo `/mnt/ssd_backup/Projects/SomeHypr` (deployed by symlinks)
```
install.sh        backup → symlink → --rollback (idempotent)
CLAUDE.md         run/verify commands for coding agents
hypr/             → ~/.config/hypr
  hyprland.lua    fixed require order; generated/* loads last, nothing else overrides
  lib/            util.lua, json.lua (vendored rxi/json.lua, MIT)
  core/           env.lua(+NVIDIA) input.lua(+tablet) look.lua motion.lua(springs) layout.lua misc.lua execs.lua
  rules/          windows.lua layers.lua gaming.lua art.lua media.lua
  binds/          keybinds.lua (1:1 port) · shell.lua (action→{somehypr=…, ii=…}) · user.lua (keybinds.json, Phase 5)
  generated/      colors.lua monitors.lua overrides.lua   (machine-written only)
  scripts/        CLI fallbacks copied from ii (record.sh, snip_to_search.sh, ocr)
  hypridle.conf hyprlock.conf
shell/            → ~/.config/quickshell/somehypr   (qs -c somehypr)
  shell.qml  core/ (Config Theme Motion Paths UiState)  services/  components/
  island/ (Island NotchShape IslandController views/)  corners/
  overview/ dock/ wallpaper/ capture/ overlay/ widgets/ lock/ osk/ settings/   (later phases)
matugen/          config.toml + templates
apps/             kitty, zen userChrome additions
```
- **State:** `~/.config/somehypr/{config,keybinds}.json` (user) and `~/.local/state/somehypr/` (colors, frecency, thumbnails).
- **Global shortcuts** use appid `somehypr`, so they never collide with `quickshell:*`.
- **Rollback:** a single `shell` variable in `hyprland.lua` picks somehypr or ii.
- **License:** end-4's code is GPL-3.0. Ported files keep that license, so the repo becomes GPL-3.0 if it's ever published.

### Anti-bloat rules (enforced in code review of every phase)
1. Every panel or view sits behind `LazyLoader`/`Loader{active}`, and unloads once its exit animation finishes.
2. Use events, not polling: native `Quickshell.Hyprland` objects, Pipewire, Mpris, Notifications, SystemTray, Networking, Bluetooth, Polkit. Polling is limited to `/proc` (1 s, only while visible) and weather (30 min, optional).
3. One color engine: **matugen only**. Terminal colors and OSC sequences come from a matugen template, with no Python.
4. Keep windows few: one island window per monitor using a `mask: Region`, plus the corner pills. No window per popup.
5. Use compositor blur (`BackgroundEffect`) and `RectangularShadow`. No Qt5Compat. `MultiEffect` only while a transition is running.

### Motion (`core/Motion.qml` + `hypr/core/motion.lua`)
- Spring presets `smooth` / `snappy` / `bouncy` / `gentle`, built on `SpringAnimation`, so they keep their velocity and retarget when interrupted.
- Hyprland window and layer animations use matching `hl.curve{type="spring"}` presets. One "motion speed" setting scales both.
- **Shared-element morph:** the island shape (width, height, per-corner radius) springs to the active view's implicit size. Content follows slightly later with fade and a 0.96→1 scale, so shape and content feel like one reaction.
- Pressable items squash to 0.96 with `bouncy`. Reduce-motion mode (and game mode) uses 120 ms fades instead.

### Island (MVP)
- **Window:**
  - Top-layer `PanelWindow` with an exclusive zone of about 32 px.
  - `mask: Region{item: shape}`, so clicks outside the notch pass through.
  - `BackgroundEffect.blurRegion` when glass is on.
  - `NotchShape.qml` draws concave top corners that merge into the screen edge, and convex bottom corners.
- **Focus:** collapsed takes no keyboard focus. Expanded uses `keyboardFocus: Exclusive` plus `HyprlandFocusGrab`, so clicking outside closes it.
- **Ambient priority:** polkit → notification peek (4 s) → OSD (volume, brightness, layout; 1.5 s) → recording/screenshare (port `services/Privacy.qml`) → media (art, marquee, peak bars, progress ring) → game-mode dot → idle clock.
- **Expanded views:**
  - Navigation: ←/→ switch views, ↑/↓/Enter act inside a view, Esc closes.
  - Views:
    - **Search** (Super tap; type immediately): apps by fuzzy search plus frecency, calculator, windows.
    - **Commands**: `/wallpaper /settings /power /lock /clip /emoji /project <name> /game /dnd /shot /ocr /record /keys`. Each command is one file `{name, icon, args, run}`.
    - **Control**: phone-style toggles plus volume, mic and DDC brightness sliders.
    - **Media**, **Notifications**, **System** (polls only while open), **Power** (hold-to-confirm).
- **Super tap:** reuse ii's proven pattern: the `SUPER + SUPER_L` bind (`~/.config/hypr/hyprland/keybinds.lua:12-22`) plus `searchToggleRelease` / `searchToggleReleaseInterrupt` (`ii/modules/ii/overview/Overview.qml:149-200`).

### Corner pills (MVP)
- **Top-left:** workspaces and the active app.
- **Top-right:** tray, US/TH layout, network, BT, volume, clock.
- A later setting can turn them into "satellites" attached to the island.

### Reuse map (from `~/.config/quickshell/ii/`)
- **Port nearly as-is:**
  - Services: `services/{Audio,MprisController,Privacy,TrayService,PolkitService,BluetoothStatus,GlobalFocusGrab,Brightness(minus anti-flashbang),Hyprsunset,MaterialThemeLoader,AppSearch}.qml`, `modules/common/functions/fuzzysort.js` + `Fuzzy.qml`.
  - Widgets: `modules/common/widgets/{StyledText,MaterialSymbol,StyledFlickable,StyledListView,StyledRectangularShadow,FadeLoader,StyledSlider,StyledSwitch,CircularProgress,NotificationItem}.qml`.
  - Lock: `modules/common/panels/lock/{LockScreen,LockContext}.qml`.
- **Port with fixes:**
  - `Notifications.qml`: debounce file writes.
  - `Cliphist.qml`: remove the duplicate refresh triggered by the IPC call in `execs.lua:19-20`.
  - `TaskbarApps.qml`: stop recreating objects on every change.
  - `LauncherSearch.qml`: keep the prefix router; reuse result objects.
  - `dock/`, `overview/` (including your special-workspace tile), `overlay/`, `regionSelector/`, `onScreenKeyboard/`, `cheatsheet/`.
  - `modules/settings/HyprlandConfig.qml` (your monitor page) and the `settings.qml` page framework.
- **Rewrite:**
  - HyprlandData → `Quickshell.Hyprland`.
  - Network → `Quickshell.Networking`.
  - ResourceUsage → runs only while visible.
  - RippleButton → `ClippingRectangle`-based press feedback.
  - Region selector smart-snap → Hyprland window rects instead of OpenCV.
  - Screen translate → tesseract + translate-shell (both installed) instead of the Google Cloud venv.

### Theming
- Move `~/.config/matugen` into the repo and drop the ags templates.
- Add templates for:
  - kitty and terminal sequences
  - KDE (`~/.local/share/color-schemes/SomeHypr.colors`, then `plasma-apply-colorscheme`)
  - Zen glass variables
  - vesktop
- `Theme.qml` holds M3 roles plus tokens: radii, spacing, fonts (Google Sans Flex for UI, JetBrains Mono for numbers) and glass alpha.
- Day/night: a schedule switches the wallpaper set, matugen mode and hyprsunset.

### Modes
- **Game mode** turns on automatically when a fullscreen window matches the game classes (steam_app_*, gamescope, *.exe, Minecraft, TwinTail titles) or gamemoded reports clients over D-Bus. It can also be toggled by hand.
  - At runtime it turns off Hyprland blur, shadows and animations, pauses mpvpaper, hides widgets, shrinks the island to a dot and suspends timers. Everything is restored on exit.
  - Hyprland keeps `allow_tearing` and the `immediate` rules, and gets `vrr=2` plus direct scanout if the monitor allows it.
- **Art:** keep the CSP rules. Map the tablet to DP-1 with locked aspect. Blender, Blockbench and Krita stay opaque, unblurred and undimmed.
- **Streamer mode:** DND, masked notification text, and notification peeks moved to a layer namespace with Hyprland `no_screen_share`.

## Roadmap
Each phase ends usable, and ii stays as the rollback until Phase 8.
`[x]` done · `[ ]` to do · `[~]` done differently (see note)

### Phase 0: Safety and toolkit ✅
- [x] Back up `~/.config/{hypr,quickshell,illogical-impulse,matugen,kitty,fuzzel,gtk-3.0,gtk-4.0}` to `~/Backups/somehypr-pre-2026-10-02.tar.zst`
- [x] `git init` the repo
- [x] Write `install.sh` (verify → backup → symlink → reload, auto-rollback on errors, `--check`, `--rollback`)
- [x] Write `CLAUDE.md`
- [x] Replace `illogical-impulse-quickshell-git` with `quickshell` 0.3.1
- [x] Confirm ii still runs on 0.3.1 (no new errors in its log)
- [x] Push to GitHub (`someact/SomeHypr`, private)

### Phase 1: Hyprland core rewrite ✅ (ii is still the shell)
- [x] 1:1 bind port through the `binds/shell.lua` action map (191 → 201 binds; the 10 new ones are Thai keycode binds)
- [x] NVIDIA env: `LIBVA_DRIVER_NAME=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `NVD_BACKEND=direct`
- [x] Thai-layout code:10-19 binds for SUPER+ALT+N
- [x] Single look file (`core/look.lua`), so nothing overrides it
- [x] Remove dead rules and files (ags/walker layer rules, touchpad gestures, `monitors.conf`, `workspaces.conf`)
- [x] Fix hyprlock (no missing scripts, wallpaper background) and theme it with matugen
- [x] Drop the easyeffects exec
- [x] Spring curves (`core/motion.lua`)
- [x] Tablet mapped to DP-1 at the screen's aspect ratio
- [x] Gaming rules list (`immediate`, `content = "game"`, idle inhibit) plus `vrr = 2` and `direct_scanout = 2`
- [x] Spike: runtime config under Lua → `hyprctl eval` / `hyprctl repl`
- [x] Game mode in Hyprland Lua (`modes/gamemode.lua`), tested on and off
- [x] Move matugen into the repo, with hypr outputs written to `hypr/generated/`
- [~] Validate in a nested `Hyprland -c` window → replaced by `Hyprland --verify-config` plus auto-rollback in `install.sh` (a nested session would have started a second ii, hypridle and clipboard watchers)
- [x] Swap the symlink live and check `hyprctl configerrors` is empty
- [ ] Hands-on check by you: Super+Alt+number on the TH layout, tablet feel in CSP, a fullscreen game turns game mode on

### Phase 2: Shell foundation and island MVP ✅ (first daily driver)
- [x] `shell/core/`: Config (JsonAdapter → `~/.config/somehypr/config.json`), Theme (matugen colors + tokens), Motion (spring presets), Paths, UiState, plus GameMode (in core so Motion can read it without a core↔services import cycle)
- [x] `shell/components/`: Icon, Label, PressButton, Slider, Toggle, GlassSurface, KeyNavList, plus IconButton, Cover (`ClippingRectangle`, no offscreen layer) and Spring (preset-driven `SpringAnimation`)
- [x] Services: Audio, Media (Mpris), Notifications, HyprData (`Quickshell.Hyprland`), Apps (fuzzy + frecency), Clipboard, Tray, Network, Bluetooth, Brightness (ddcutil), KbLayout, Privacy, GameMode bridge, plus Osd, Calc (qalc), Emojis, SysStats, NightLight, Session, Wallpaper, Keybinds
  - [~] Notifications stay in memory (newest 50) instead of a history file, so there is nothing to rewrite per event
  - GameMode bridge: `modes/gamemode.lua` emits socket2 `custom>>somehypr_gamemode,<0|1>`; the shell never polls
- [x] Island window: notch shape, input mask, `BackgroundEffect` blur, focus grab (activated 50 ms after opening, same race ii works around)
- [x] Ambient states: polkit, notification peek, OSD, recording/screenshare, media, game-mode dot, idle clock
- [x] Super-tap search (apps, calculator, windows). Hyprland only delivers the release of `SUPER + SUPER_L`, so the bare `superKey` press arms the tap; it counts if Super was alone, held < 500 ms, with no workspace/window event or other shell shortcut in between. Tested with `ydotool`: tap opens, tap closes, Super+V / Super+2 / unbound combos / long hold do not
- [~] Commands view → `/` inside search, one file per command in `shell/commands/` (`/wallpaper /settings /power /lock /clip /emoji /project /game /dnd /shot /ocr /record /keys`), Tab completes, `/project` suggests folders
- [x] Control view (toggles + volume/mic/brightness sliders)
- [x] Media, Notifications, System, Power views
- [x] Clipboard and Emoji views (plus a Keys view for `/keys`)
- [x] Corner pills: workspaces + active app (left), tray/layout/net/BT/volume/clock (right)
- [x] Plain wallpaper background layer (steps aside for video wallpapers until Phase 3)
- [x] Native Polkit agent
- [x] Global shortcuts under appid `somehypr`, IPC targets for every view (`qs -c somehypr ipc call island open <view>`)
- [x] Switch `shell = "somehypr"` in `hypr/user.lua` (live; somehypr owns notifications and the polkit agent; 199 binds, since the panel-family and welcome binds are ii-only)
- [x] Region tools and overlay fall back to CLI scripts for now (the `somehypr:region*` shortcuts run them)
- [ ] Memory: glvnd is pinned to the NVIDIA EGL vendor in `shell.qml`, so Mesa + LLVM no longer load (fresh dev run: 485 → ~385 MB RSS). Live after opening views: ~480 MB RSS, PSS ~300 MB (~210 MB of it heap). Still above the 250 MB target; the Phase 8 audit owns this
- [ ] Hands-on check by you: Super tap (and Super+1 not opening search), typing straight into search, ←/→ between views, glass blur behind the notch, tray menus

### Phase 3: Wallpaper and theming ✅
- [x] `/wallpaper` picker with cached thumbnails (island view, Ctrl+Super+T; ffmpeg thumbnails in `~/.cache/somehypr/thumbs`, made on demand one at a time; arrows/Enter, R random, D dark/light, O file dialog). Image wallpapers crossfade
- [x] mpvpaper video wallpapers (`hwdec=nvdec`, verified active), paused during games, fullscreen and lock (`-p -a FULL` pauses when hidden or a window is fullscreen; game mode also pauses over mpv's IPC socket, verified)
- [x] Extract a video frame for matugen (ffmpeg, 1 s in → `~/.local/state/somehypr/video-frame.jpg`)
- [x] Day/night schedule (wallpaper set, matugen mode, hyprsunset): `theme.schedule` in config.json, off by default; checked on the minute clock only while enabled, applied once per phase
- [x] matugen-only terminal colors (replace ii's Python + `applycolor.sh`): `custom_colors` blend a fixed ANSI palette toward the wallpaper; kitty reloads on SIGUSR1, other terminals get OSC sequences (`matugen/hooks/term-sequences.sh`)
- [x] App templates: GTK, Qt/KDE color scheme, kitty, Zen glass, vesktop
  - GTK 3/4 plus `gsettings color-scheme prefer-<mode>`
  - KDE `SomeHypr.colors`, applied by `matugen/hooks/kde-colors.sh` (alternates SomeHyprA/B because Plasma ignores re-applying the same name); no more kde-material-you-colors venv
  - Zen: `chrome/somehypr-colors.css` imported by `userChrome.css` (+ `user.js` pref); applies on Zen's next start
  - Vesktop: `themes/somehypr.theme.css`, enabled in its settings
  - Edited user files were backed up as `*.pre-somehypr` (kitty.conf, vesktop settings.json)
- [x] Colors now live in `~/.local/state/somehypr/`; ii's old outputs are still written for rollback (`ii_*` templates, remove in Phase 8)
- [x] matugen 4 needs `--source-color-index 0` without a terminal (it failed silently from the shell before)
- [ ] Note for Phase 8: mpvpaper with a 1080p video uses ~760 MB RSS

### Phase 4: Dock and Overview ✅
- [x] Bottom dock: pinned + running apps (`dock/`, `services/Taskbar.qml`). Windows are grouped by app id; the model is a `ScriptModel` over plain app-key strings, so delegates survive window changes (ii's `TaskbarApps` recreated every entry). Click focuses the last used window or cycles, middle-click opens a new window, wheel cycles windows. Pinned apps carried over from ii, stored in `config.json` `dock.pinned`
- [x] Intellihide, drag to reorder, context menu
  - `dock.autohide`: `intelli` (hide while a window on the monitor's visible workspace, or its open scratchpad, overlaps the dock; always hidden over fullscreen), `auto` (hover only), `never` (always shown, reserves space). The bottom 2 px strip reveals it
  - Window rects come from `HyprlandToplevel.lastIpcObject`, refreshed over the socket (no process), debounced, only on window/workspace events and only while intellihide or the overview needs it. Dragging a floating window with the mouse emits no event, so the dock catches up on the next focus/window event
  - Drag reorders pinned apps live; dropping a running app among them pins it; pulling a pinned app up out of the dock unpins it
  - Right-click menu (windows, desktop actions, new window, pin/unpin, close) is drawn inside the dock window; a focus grab closes it
- [x] Overview (Super+Tab): live `ScreencopyView` only while open. The whole window sits behind a `LazyLoader` (+~9 MB while open, released on close). Overlay layer, compositor frost behind it, wallpaper on every tile
- [x] Overview drag-and-drop between workspaces, special-workspace tile ("Scratchpad"; dropping a window there sends it to `special:special`). Click a tile/window to go there, middle-click closes a window, arrows + Enter, 1–0 jump, Esc closes, typing anything else hands the text to island search
- [x] Fix: an empty `BackgroundEffect.blurRegion` blurs the *whole* surface (with `xray` that paints the wallpaper over every window). The dock, the island and the pills now drop the region whenever their shape is slid off-surface (dock hidden, Super+J)
- [ ] Hands-on check by you: intellihide feel with floating windows, drag-to-reorder and drag-out-to-unpin, overview drag between workspaces

### Phase 5: Settings app and keybinds ✅
- [x] Separate `qs -p` settings window, unloaded when closed (`shell/settings.qml`; closing the window ends the process, ~400 MB RSS only while open). `ipc call settings open` / `settings page <id>` and `/settings [page]` focus the running window instead of starting another
- [x] Pages: Appearance (notch / floating / satellites, glass, motion), Island, Dock, Wallpaper
  - Island styles are live: **floating** is a free pill level with the corner pills; **satellites** also pulls the pills beside the island, following its width as it morphs
  - Shell settings write `config.json` (the shell reloads it live); wallpaper, mode and scheme go to the running shell over IPC
- [x] Keybinds page: edits `keybinds.json`, checks conflicts against `hyprctl binds -j`, then `hyprctl reload`
  - `hypr/binds/user.lua` wraps `hl.bind` while keybinds.lua runs, so keybinds.lua stays the untouched 1:1 port; remap, turn off, reset, custom shortcuts (`exec`)
  - Recording parks Hyprland in an empty `somehypr-record` submap so already-bound combos can be recorded (always left on capture/cancel/10 s; CTRL+ALT+Escape escapes). Keys are recorded by keycode with US names, so Shift and the Thai layout don't change them
  - A conflicting combo is not saved until "Use anyway"
- [x] Hyprland + monitors page (port your page), Autostart, Modes
  - [~] Hyprland options live in `~/.config/somehypr/hypr.json` (only changed keys, applied last by `core/settings.lua`) instead of a generated `overrides.lua`; the page shows Hyprland's live values and a reset per option. `lib/json.lua` is a small decoder written for this, not vendored rxi
  - Displays (port of the ii page) writes `hypr/monitors.lua`, with an arrangement preview and a 15 s keep-or-revert after Apply
  - Apps & Autostart: default apps (override user.lua) and autostart commands (run by `core/execs.lua`); Modes: game mode auto/force, DND
  - Config errors after any change show in a banner
- [x] Island `/keys` cheatsheet built from bind descriptions: grouped with key caps, includes custom shortcuts; Enter opens the Keybinds page
- [ ] Hands-on check by you: record a few shortcuts (incl. on the TH layout), try floating/satellites, Displays apply + revert

### Phase 6: Capture and gaming tools
- [ ] Region tools UI: screenshot, OCR, Lens, translate (Super+Shift+S/X/A/T)
- [ ] Record with an island indicator
- [ ] Game overlay (Super+G): crosshair, fps limit, notes, resources, mixer
- [ ] Game mode polish (gamemoded D-Bus, pause mpvpaper, hide widgets)
- [ ] Streamer mode (DND, masked notifications, `no_screen_share`)

### Phase 7: Lock, widgets, OSK
- [ ] Quickshell lock screen, hyprlock as automatic fallback
- [ ] Desktop widgets (clock, media, system, notes) with drag edit mode
- [ ] On-screen keyboard (Super+K)

### Phase 8: Audit and retire ii
- [ ] Measure against the Targets
- [ ] Remove ii from autostart and the `hypr/hyprland/scripts` compat link
- [ ] Optional cleanup for approval: ii venv, unused Plasma services, `illogical-impulse-*` meta packages
- [ ] Optional experiment: hyprglass refraction plugin

## Verification
- **Hyprland:**
  - `hyprctl configerrors` is empty.
  - `hyprctl binds -j | jq length` is 200 with `shell = "somehypr"` (202 with ii: 191 plus 10 Thai keycode binds plus the record-submap escape) when `keybinds.json` adds nothing.
  - Spot-check options with `hyprctl getoption`.
  - SUPER+ALT+N works with the TH layout active.
- **Shell:**
  - `timeout 12 qs -c somehypr 2>&1 | grep -E "WARN|ERROR"` shows no new ReferenceError or TypeError.
  - Every view can be opened through `qs -c somehypr ipc call island open <view>`.
- **Performance:**
  - `ps -o rss,pcpu -C qs` after 10 min idle is ≤ 250 MB.
  - `pidstat -p $(pidof qs) 1 60` averages about 0%.
  - Hyprland `debug:overlay` shows frames under 10 ms during island morphs.
  - `QSG_RENDER_TIMING=1` for scene-graph cost.
- **Game mode:** launch a Steam game and check that blur, shadows and animations are off, mpvpaper is paused and the island is a dot. After exiting, everything is restored.
- **Rollback drill:** `install.sh --rollback && hyprctl reload` brings back the exact ii setup.
