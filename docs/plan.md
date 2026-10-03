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
  overview/ dock/ wallpaper/ capture/ overlay/ widgets/ lock/ osk/ settings/
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
- [ ] Memory: glvnd is pinned to the NVIDIA EGL vendor in `shell.qml`, so Mesa + LLVM no longer load (fresh dev run: 485 → ~385 MB RSS). Live after opening views: ~480 MB RSS, PSS ~300 MB (~210 MB of it heap). Still above the 250 MB target; see the Phase 8 audit
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

### Phase 6: Capture and gaming tools ✅
- [x] Region tools UI: screenshot, OCR, Lens, translate (Super+Shift+S/X/A/T), `capture/RegionSelector.qml` + `services/Capture.qml`
  - grim freezes the focused monitor; the selector shows that frame (window only exists while selecting). Drag selects, click takes the window under the cursor (Hyprland window rects, topmost first; no OpenCV), Enter takes the whole monitor, right-drag a screenshot to annotate in swappy, Tab / 1–6 switch the tool, Esc cancels
  - magick crops the frozen frame. Screenshot → clipboard (optional save folder), OCR → clipboard (all installed tesseract languages), Lens → uguu.se + Google Lens (as before), translate → tesseract + translate-shell into an island `translate` view (Enter copies, Tab cycles ไทย/English/日本語; `/translate <text>` works without a region)
  - Feedback goes through the island OSD ("Screenshot copied", "Copied N characters")
  - [ ] Note: tesseract only has `eng` installed; Thai OCR needs `tesseract-data-tha`
- [x] Record with an island indicator: `services/Recorder.qml` owns wf-recorder (NVENC by default, `capture.encoder`), stops with SIGINT so the file is finalized. The island shows a red dot, the timer and a stop button (click stops); "Recording saved" notification. Super+Shift+R / Super+Alt+R region, Ctrl+Alt+R screen, Super+Shift+Alt+R screen + sound (now shell actions with `record.sh` as fallback, 202 binds). `/record [screen] [sound]`, Control view toggle
- [x] Game overlay (Super+G): crosshair, FPS limit, notes, resources, mixer (`overlay/`)
  - Overlay-layer window loaded only while open or while something is pinned; draggable cards (positions in `config.json` `overlay.positions`), pin keeps a card on screen click-through after closing (empty input mask), 1–5 toggle cards, Esc closes, quick screen record (+sound) in the toolbar
  - No compositor blur here: layer blur uses `xray`, which would paint the wallpaper over the game
  - Crosshair is plain rectangles (length, gap, thickness, dot, outline, color); FPS limit writes MangoHud's `fps_limit` (MangoHud reloads it); resources use SysStats only while visible; mixer = per-app Pipewire streams; notes save to `~/.local/state/somehypr/notes.md`
- [x] Game mode polish
  - gamemoded over D-Bus: `services/GameClients.qml` runs one `gdbus monitor` (GameRegistered/GameUnregistered carry the PID, no polling) and sends the PID list to `GameMode.set_clients()`. A focused window owned by a client is a game even windowed; any fullscreen window counts while a client exists (Proton PIDs can differ). Tested with `gamemoderun kitty`: on while focused, off after exit
  - mpvpaper pause: done in Phase 3; dock hidden and island dot already in place
  - [x] Hide widgets: desktop widgets (Phase 7) unload while `GameMode.active`. Overlay cards stay (they are meant for games)
- [x] Streamer mode (`services/Streamer.qml`, `/stream`, Control view, Modes page): DND (critical still peeks), notification text and images masked in the island, peeks moved to the `somehypr:private` layer with `no_screen_share` (verified: grim sees a black box). Turns on by itself while the screen is shared over Pipewire (`streamer.auto`); turning it off by hand holds until the share ends
- [x] Settings: new Capture page (window snapping, save shots + folder, translate target, encoder, recordings folder); Modes page gained Game overlay and Streamer sections
- [ ] Hands-on check by you: region tools by mouse (window click, right-drag edit, Lens), Super+G over a real game with a pinned card and the crosshair, a gamemoderun Steam game, streamer mode during an OBS/Discord share

### Phase 7: Lock, widgets, OSK ✅
- [x] Quickshell lock screen, hyprlock as automatic fallback
  - `lock/LockScreen.qml` (`WlSessionLock`, a surface per screen only while locked) + `lock/LockSurface.qml`, state and PAM in `services/Lock.qml` (`login` stack, so faillock messages show under the field)
  - Big clock and date, avatar (`~/.face` or initial), dot field with shake on failure, Caps Lock hint (inferred from typed letters vs Shift), clickable US/TH chip (a Thai password on the US layout is the classic failure), notification *count* only, now playing with controls, suspend + restart/shut down (second click)
  - Wallpaper blurred once by ImageMagick (downscale → blur → upscale) into `~/.cache/somehypr/lock-blur.jpg`, remade only when the wallpaper or video frame changes, warmed 4 s after a change; no live blur
  - `session_lock_xray` keeps the desktop drawn underneath, so entry and unlock fade to/from the real desktop
  - `scripts/lock.sh`: `qs -c somehypr ipc call lock lock`; if no instance answers (not running, crashed) → `hyprlock`. Config `lock.useHyprlock` hands every lock to hyprlock. No unlock IPC on purpose
  - Preview (`ipc call lock preview`, Desktop page) shows the same screen in an overlay window without locking or PAM
  - Locked binds can stop a recording but never open the region picker or start one
  - [~] Tested: preview (typing, Caps Lock, layout chip, Esc), PAM conversation (asks `Password:`, aborted unanswered so faillock stays clean). A real lock/unlock needs your password → hands-on check
- [x] Desktop widgets (clock, media, system, notes) with drag edit mode
  - `widgets/DesktopWidgets.qml`: one bottom-layer window per screen, loaded only while a widget is on and game mode is off; input mask = the widgets; frosted cards via `BackgroundEffect` (never an empty region)
  - Edit mode (right-click a widget, `/widgets`, Desktop page, `ipc call widgets edit`): window moves to the top layer, dims the desktop, drag snaps to 8 px and stays on screen, ✕ removes, the bar adds widgets / toggles frost / resets; Esc or Done ends it. Positions in `config.json` `widgets.positions`
  - System polls (SysStats) and media progress ticks only while the monitor's workspace has no windows (or in edit mode); verified `nvidia-smi` stops when covered
  - Notes share `notes.md` with the overlay card (file watched; not reloaded while typing)
- [x] On-screen keyboard (Super+K)
  - `osk/Osk.qml` overlay layer with no keyboard focus, so keys reach the focused window; `services/VirtualKeys.qml` types through ydotoold — one `ydotool key` call per tap (modifiers down, key, modifiers up), so nothing can stay stuck
  - Sticky Shift/Ctrl/Alt/Super: tap latches for one key, double tap locks; backspace, space, Del and arrows repeat while held
  - Labels follow the active layout: US, or Thai Kedmanee from xkb `symbols/th` (combining marks drawn on ◌); layout button switches US/TH
  - Pin reserves space (exclusive zone); key size setting; `/osk`, `ipc call osk toggle`
  - Tested with real clicks into a test window: `Hi` (latched Shift), `OK` (locked Shift), Enter, and `กด` on TH
- [x] Settings: new Desktop page (widgets, lock screen options + preview, keyboard)
- [ ] Hands-on check by you: Super+L and unlock with your password (also on TH layout and after suspend), idle lock after 5 min, widgets on an empty workspace + edit mode drag, OSK typing into a real app

### Phase 8: Audit and retire ii ✅
- [~] Measure against the Targets (live `qs -c somehypr`, one monitor, image wallpaper)

  | Target | Result |
  |---|---|
  | Idle RSS ≤ 250 MB | **Not met as written:** 414 MB fresh, 469 MB after 10 min with normal use (was 720 MB before this phase). The target is below the floor: an empty one-window Quickshell already shows ~250 MB RSS / ~55 MB anon / ~105 MB PSS on this NVIDIA stack (shared Qt + driver libraries). What the shell itself adds: ~170 MB anon fresh, ~210 MB after use (it settles there; no leak over a 3 min idle sample) |
  | ~0% CPU idle, no timer < 1 s unless visible | **Met:** 0–0.15% over 60 s samples; every repeating timer is gated (SysStats/media/recorder/OSK repeat/display revert) |
  | No Python, cava, nmcli polling, separate polkit agent | **Met:** none running; only child process is the gamemoded `gdbus monitor` |
  | Interruptible springs at 100 fps | Springs retarget (Phase 2); frame times not measured with `debug:overlay` → hands-on check |
  | Game mode → near-zero overhead | Done in Phases 1/3/6 (blur, shadows, animations off, mpvpaper paused, widgets unloaded, island dot) |

  Fixes found by the audit:
  - `components/Icon.qml` animated the Material Symbols `FILL` axis and used any size as `opsz`. Qt opens one face per distinct axis value (mmap of the 14 MB font + glyph cache), so a session reached 42 mappings (199 MB of RSS, ~10 MB PSS). FILL now snaps to 0/1 and opsz to 20/24/40/48: 4–5 mappings
  - Wallpaper: a 3000×2000 JPEG decoded with `sourceSize` kept +39 MB anon vs +15 MB for a screen-sized file. The layer now shows a cached ImageMagick copy (`~/.cache/somehypr/wall-<WxH>-<md5>.jpg`, old ones pruned), frees the faded-out crossfade slot, and frees both while a video plays
  - Measured and ruled out: surface size and window count (GPU memory, ~0 process cost), text render type, malloc arenas, QML JS heap (~1 MB)
  - Bisect of the remaining anon (each part alone over the floor): wallpaper ~45 MB (before the fix), island ~30, dock ~28, pills ~20, everything lazy ~5. Going further needs a heap profiler (`heaptrack`, not installed)
- [x] Remove ii from autostart and the `hypr/hyprland/scripts` compat link
  - The `shell` switch is gone: `binds/shell.lua` maps each action to a `somehypr:` shortcut + CLI fallback; execs, env (`qsConfig`, ii venv), layer rules, window rules, `lock.sh` and `record.sh` (now reads `capture.recordDir`) are somehypr-only
  - matugen no longer writes ii's outputs (`ii_*` templates, `kde/color.txt`, the kde-material-you wrapper removed); the shell's one-time ii wallpaper migration removed
  - Binds: 201 (the wallpaper action lost ii's `switchwall.sh` fallback; panel-family/welcome were already unbound)
  - `~/.config/quickshell/ii` and `~/.config/hypr.pre-somehypr` stay on disk, so `install.sh --rollback` still works
- [ ] Optional cleanup for approval: ii venv (`~/.local/state/quickshell/.venv`, 331 MB), unused Plasma services (`kded6` 150 MB + `kactivitymanagerd` 89 MB RSS, both D-Bus/systemd activated), 13 `illogical-impulse-*` meta packages
- [x] Optional experiment: hyprglass refraction plugin → done in Phase 9a (Liquid glass)
- [ ] Note: mpvpaper with a 1080p video still uses ~760 MB RSS (Phase 3); not re-measured here
- [ ] Hands-on check by you: island morph smoothness after the Icon change (fill no longer fades), wallpaper picker crossfade, Super+Shift+R with the shell killed (record.sh fallback)

### Phase 9: Refine ✅ (glass, expressive icons, island UX)
Workflow from Phase 9 on: commit and push after each task (see CLAUDE.md → Phase workflow). 9a and 9a+ landed together in one commit before this rule.
From `Improvement idea.md` (2026-10-03). Style: ii's Material 3 Expressive icons (Android/ChromeOS) + Apple-style glass and motion.
Decisions: "dock" = island + top pills (bottom dock gets only the new icon/glass style); hover shows a peek and a click or Super opens the full view; real blur of the windows behind (no `xray` on shell layers); the translator is a pinned live area.

Root causes found:
- Pixelated edges and wallpaper behind the island: `rules/layers.lua` sets `xray = true` on every layer, so the blur samples only the wallpaper. Also, `Region` corners are integer-pixel steps while `NotchShape` is anti-aliased, and the ears sit outside the blur region.
- Not "true glass": the island is black at 0.72 alpha with no rim or highlight; the overlay is black at 0.78 with no blur.
- Toggles reset and skip frames: `ControlView.toggles` is one array bound to every live value, so any change (the recording timer, the network name) recreates every Toggle.
- Lock dots: `Repeater { model: <int> }` rebuilds every dot on each key press.
- Workspaces: the left pill always draws all 10 and never shows special workspaces.

**9a. Glass foundation**
- [x] `xray = false` for the `somehypr:*` glass layers (island, pill, dock, overview, overlay, widgets, osk); game mode still turns blur off
  - Verified with grim: the open island, overlay cards and OSK frost the terminal and browser behind them
- [~] `components/Glass.qml` (replaces GlassSurface): lighter tint, 1 px gradient rim, inner top highlight; `Theme.glass*` tokens; the island keeps a darker "hardware" tint option
  - The rim is a flat 1 px light border; the top highlight gradient gives the light-top look (Qt cannot draw a gradient border cheaply). Tints: pill/card 0.4 (was 0.55), island 0.55 black (was 0.72); without frost (glass off, game mode) they turn near-opaque. New `Theme.blur` = glass on and not game mode
- [x] Edge fix: blur region inset 1 px under the anti-aliased rim, ears covered, integer radii
  - `components/GlassRegion.qml`, `Glass.frost`/`frostRadius`; the island region is hand-built (no inset at the screen edge) with three 2 px strips per ear inside the concave curve. The notch rim stroke leaves the top edge open, so no line shows at the screen edge
- [x] Apply to the island, pills, dock, overview, widgets, OSK and overlay (overlay gets `BackgroundEffect`); update the CLAUDE.md gotchas
  - Overlay: the bar and open cards are frosted; pinned click-through cards stay plain dark. Game mode disables compositor blur, so `GameMode.overlay(open)` (`modes/gamemode.lua`, called from `core/GameMode.qml`) turns it back on only while the overlay is open
- [x] Settings → Appearance: glass strength and rim on/off
  - Glass tint, Island tint, Rim light (`config.json` `glass`)

**9a+. Liquid glass and island options** (added 2026-10-03, on request)
- [x] hyprglass plugin as an option: `liquidGlass` (off by default), `liquidGlassPreset` (pomme), `liquidGlassWindows` in `user.lua` / hypr.json; `hypr/core/liquidglass.lua` loads it only if built for the running Hyprland version
  - `hypr/scripts/hyprglass.sh` builds upstream's `hyprland-<x.y>` branch + `hypr/plugins/hyprglass-fit-shape.patch` into `~/.local/share/somehypr/plugins/hyprglass-<version>.so` (no hyprpm on this system)
  - The patch: on layers, upstream glass covers the whole layer surface with square corners, and the shell's surfaces are larger than what they draw. With `layers:fit_shape` the glass is the rounded box the blur region outlines (radii read from the region, grown back the 1 px inset), and the shader measures refraction, lens, specular and bezel on that box (identity for windows)
  - Only island, pill, dock and OSK get it (one shape per surface); the overlay and desktop widgets keep plain blur; windows are tagged `hyprglass_disabled` unless `liquidGlassWindows`
  - Crash found and fixed: `hl.plugin.load()` is declarative and must run on every config load. Skipping it once the plugin was loaded made Hyprland unload, load and reload in a loop until it segfaulted (3 crashes on 2026-10-03). Verified in a nested Hyprland: on, reload, off (clean unload), on again; then live: two reloads, no config errors, 201 binds
  - Cost (live, video playing): Hyprland CPU 9.5→9.7 %, GPU 24.5→21.5 %, power 51→49 W, all within noise; +~40 MB VRAM; Hyprland RSS unchanged. Stats: ~4 layer draws per frame, background re-sampled only on change (~79 % cache hits)
- [x] Settings → Appearance → Liquid glass: Build button (runs the script) when the plugin is missing, then the on/off switch, Look (Pomme/Clear/Subtle/Glass), On windows too
- [x] Island glass on/off: off keeps only the island solid black (no frost, no rim); pills, dock and cards stay glass (`config.json` `glass.island`, `Theme.islandBlur`)
- [ ] Hands-on check by you: a wrong password on the real lock screen (shapes stay through the shake, then clear); Liquid glass look over real windows, which preset you like, and that the island tint (0.55) does not hide the effect too much

**9a++. README and workflow** (added 2026-10-03, on request)
- [x] `README.md`: how it works (repo layout, Hyprland load order, the shell's parts, settings files), install, update, liquid glass, checks
- [x] Workflow: commit and push per task, with new requests tracked in the plan first (CLAUDE.md → Phase workflow)

**9b. Expressive icon and type style**
- [~] Port ii's `MaterialShape` + `shapes/` to `components/Shape*.qml`
  - Shape math vendored unchanged in `shell/lib/shapes/` (Apache-2.0, attribution README); `components/MaterialShape.qml` draws it with QtQuick.Shapes (CurveRenderer) instead of ii's Canvas, so no offscreen texture per shape. `shape` changes morph with a spring; the path is rebuilt only during the morph. Verified all 35 names render and morph (grim)
- [x] `components/ShapeIcon.qml`: floating icon with no background and an outline or soft shadow; tinted shape only when active
  - The halo is a glyph outline (`Text.Outline`, black 35 %), not a shadow effect, so it adds no layer; active springs the shape in (bouncy) and fills the icon. Verified on a light background (grim)
- [x] Toggles, IconButton and PressButton morph their corner radius (pill ↔ squircle) when active
  - `PressButton.radius` (rest) / `activeRadius` (on), a press tightens the corners to 80 %, all on a retargeting spring. Toggle tiles: pill off, 14 px squircle on; IconButton: circle off, 32 % squircle on. Buttons that set only `radius` keep their shape. Verified in the Control view (grim)
- [x] Type: titles at wght 550, tabular numbers; Material Symbols face count stays ≤ 5
  - `Theme.font.weight` 450 (body, every Label) and `weightTitle` 550 (was DemiBold 600 in 41 places), set with `font.weight` (the variable font's wght axis), not `variableAxes`. Label digits are always tabular
  - Fresh shell after opening every main view: Google Sans Flex 1 mapping, Material Symbols 5, anon 152 MB (Phase 8 fresh: ~170 MB)
  - Found: both fonts load from ii's `ii-sddm-theme-fonts` package; README warns to copy them before removing ii packages
- [x] Pill icon style setting: `floating` (phone status bar) / `glass`
  - Settings → Island → Corner pills (`island.pillStyle`). Floating: no background or blur; text, icons and workspace dots are white with a 60 % dark glyph halo (`Theme.fgPill`, `pillHalo`). On a very bright wallpaper white text stays a little weak (no per-wallpaper adaptive color yet)

**9b+. Pill parts and halo** (added 2026-10-03, on request)
- [x] Floating text and icons: halo choice, soft shadow or outline
  - Settings → Island → Floating text (`pills.halo`, default shadow). Shadow: one MultiEffect drop shadow per floating pill (black 90 %, blur 0.35), only while floating. Outline: the glyph outline (no layer). Compared over a bright wallpaper (grim)
- [x] Workspaces drawn with the Material shapes: the active one morphs into an expressive shape with its number (added on request)
  - Each workspace is a `MaterialShape`: empty 5 px dot, occupied 7 px, active 20 px `pills.workspaceShape` (Cookie, Clover, Sunny, Pill, Circle in Settings → Island) with its number; switching morphs and resizes on springs. Verified mid-switch frames (grim)
- [x] Password characters on the lock screen as Material shapes; only the typed or deleted one animates (covers 9g's lock dots item)
  - A fixed pool of 22 shape slots (shapes shuffled per lock): typing grows only the new one (bouncy scale + spin), backspace shrinks only the last, the row slides to stay centered; the placeholder fades in as the last shapes leave. A wrong password keeps the shapes through the shake (360 ms) and then clears them together. Verified typing, backspace and Esc in `lock preview` with ydotool (grim); the wrong-password path needs PAM → hands-on check
- [x] Glass or floating per part of the corner pills (workspaces, app title, system tray, status icons, clock); neighboring glass parts join into one pill
  - `corners/PillPart.qml` per part (`Config.pills.<part>`); `CornerWindow` lays the visible parts out, draws one Glass per run of glass parts with dividers inside, blurs only those runs (no region when every part floats) and springs positions. Replaces the single `island.pillStyle`. Settings → Island → Corner pills: a Glass/Floating row per part plus Floating text. Verified all-glass (same look as before), floating workspaces + glass title, glass status + floating clock (grim)

**9c. Corner pills and workspaces**
- [x] Fix: the active workspace shape gets cut off (added 2026-10-03)
  - Cause: a floating part's shadow layer renders only its row's exact bounds, which flattened the 20 px shape's bumps and its spring overshoot. The row now has 3 px padding inside the layer (content not moved). Verified frames mid-switch (grim)
- [x] Show only occupied workspaces plus the active one; they spring in and out; setting "show empty workspaces" (default off)
  - The 10 group slots stay (no rebuild); a hidden slot springs to zero width and fades/scales out. Settings → Island → Show empty workspaces (`pills.showEmpty`). Holding Super shows all. Verified switching to an empty workspace and back (grim)
- [x] Holding Super: every workspace of the group appears as a shape with its number (empty ones as outlines), redesigned from the plain numbers (added 2026-10-03)
  - Held: every slot morphs into `pills.workspaceShape` (18 px; active 20 px in the accent), filled with a dark number when it has windows, an outline with a dim number when empty; release morphs back to dots. Verified with ydotool holding Super (grim); the island did not open
- [x] Special-workspace chip (click toggles it)
  - A part after the workspaces (same style): a star `ShapeIcon` per special workspace with windows, plus its name unless it is the default `special`; the shape lights while it is open on this monitor. Verified with a window moved to `special:test`: chip appears, lights when toggled open, goes away when the window closes (grim)
- [x] Island style and pill placement split: the island is notch or floating, and pills can sit beside the island with either (satellites with a notch) (added 2026-10-03)
  - Island style is Notch or Floating; "Satellites" is gone, it is now placing parts beside the island (clears the notch's ears). Verified notch with workspaces left and status + clock right of it, sliding out when the island opens (grim)
- [x] Pill layout: each part (workspaces, title, tray, status, clock) can go to the left or right corner or beside the island, be reordered, and be shown or hidden; editor in Settings → Island (added 2026-10-03)
  - `corners/PillParts.qml` holds every part by id (workspaces, special, title, tray, status, clock); `corners/Pills.qml` makes up to four zone windows per screen (left, islandLeft, islandRight, right), each only while its list in `pills.layout` is non-empty; `CornerWindow` loads its zone's parts in order. Settings → Island → Pill layout: place (Left, ◂ Island, Island ▸, Right, Off) and ‹ › to reorder. Verified clicks: moving Workspaces to the right corner and reordering it before the tray

- [x] "Dynamic" active workspace shape: a fixed shape per workspace number (like the password shapes, but stable) (added 2026-10-03)
  - Settings → Island → Active workspace shape → Dynamic: 1 cookie4, 2 clover4, 3 cookie7, 4 sunny, 5 flower, 6 soft burst, 7 pentagon, 8 cookie9, 9 clover8, 10 puffy (repeats per group); also the Super-held view. Verified switching 1 → 2 morphs cookie → clover and the held view shows all ten (grim)

**9d. Island interaction**
- [x] Hover peek (~180 ms) with a top-edge hot strip; leaving closes it after ~300 ms; a click or Super opens the full view; no keyboard focus; off in game mode and fullscreen
  - `UiState.peeking`/`peekScreen` + `peek()`/`unpeek()`/`promote()`; the island renders a view while `open || peek`, keyboard focus and the focus grab only when open. Peeks the view a click would open (notification → Notifications, media → Media, otherwise Control); never while polkit waits. Hot strip: 2 px at the top edge, 16 px wider than the island on each side, in the input mask. A passive `PointHandler` over the peek promotes on any press, so the pressed button still acts; a Super tap promotes too. Settings → Island → Peek on hover (`island.hoverPeek`). Verified: hover peeks (grim), leaving closes, click on a tab promotes and stays open after leaving, Super tap promotes, no peek over a fullscreen window; `island state` reports `peeking`
  - Found (not new): a ydotool click outside does not clear the island's focus grab, with or without this change
- [x] Workspaces peek with the mouse too: hovering the workspaces part shows every workspace as its shape, like holding Super; setting to turn it off (added 2026-10-03)
  - A `HoverHandler` on the workspaces part (150 ms in, 300 ms grace out, so the part growing under the cursor does not flicker) drives `wsPart.peek` = Super held or hover, which replaced `UiState.superHeld` in the slots. Settings → Island → Show all workspaces on hover (`pills.hoverPeek`, default on). Verified rest → hover → 200 ms after leaving → closed (grim)
- [x] Fix: a glass pill's blur stayed behind when the pill slid at a fixed width (the title after the workspaces peek collapsed) (added 2026-10-03)
  - Cause: `Region { item: run.frost }` updates only when the frost item's own geometry changes, not when an ancestor moves. `CornerWindow` now binds each run's region to window coordinates (`RunRegion`, `bar.x + run.x`, inset 1 px). Verified mid-collapse and settled frames after a hover peek (grim)
- [x] Quick options: a stable tile model (`services/QuickTiles.qml`) that fixes the frame skip; icon or full tiles; edit mode (add, hide, reorder) stored in `control.tiles`
  - One long-lived `Tile` object per id (wifi, bluetooth, dnd, game, nightlight, caffeine, mic, dark, streamer, record, plus new screenshot and keyboard), each property bound to its own source, so a change updates one property and no delegate is recreated. `island/views/TileGrid.qml` keeps one delegate per id and springs each to its slot. `control.tiles` (shown, in order) and `control.tileStyle` (`full`, 2 per row / `icon`, 8 per row); the pencil and grid buttons above the tiles. Edit mode: −/+ badges, click shows or hides, drag a shown tile to reorder (others slide live, saved on release), hidden ones in a row below; Esc/Enter leaves it. Tiles without hardware (no Bluetooth adapter) are left out. Verified by real clicks: hide, drag to reorder, icon style (grim)
- [x] Right-click detail pages: Wi-Fi list, Bluetooth devices, night light temperature, audio devices; other tiles open their settings page
  - Pages replace the tiles inside the Control view (← or Esc goes back): `NetworkDetail` (wired links with speed; with Wi-Fi hardware the scanned networks, scanning only while open, connect/disconnect, inline password for new secured ones, forget saved), `BluetoothDetail` (adapter switch, discovery only while open, paired then available, click connects/disconnects/pairs-then-connects, forget; unnamed devices hidden), `NightLightDetail` (switch, 2500–6500 K slider applied live through `hyprctl hyprsunset temperature`, presets; stored as `theme.nightLightTemp`), `AudioDevices` (output and input pickers through `Pipewire.preferredDefaultAudio*`). Microphone → sound devices; DND, game, streamer → Modes, caffeine and keyboard → Desktop, dark mode → Wallpaper, record and screenshot → Capture. New `components/PillSwitch.qml`, `island/views/DetailRow.qml`; `Audio.sinks/sources/streams` + name/icon helpers
  - Verified by right-clicks (grim): Ethernet 1000 Mb/s, Bluetooth searching (discovery off after closing), night light, both ALC897 and the monitor's HDMI output; Keep awake opened Settings → Desktop. Not testable here: the Wi-Fi list and password (no Wi-Fi hardware), pairing (no device nearby), the live temperature change (night light was off) → hands-on check
- [x] Mixer: right-click volume → `MixerView` (per-app streams, output and input pickers); shared `Audio.streams`
  - `island/views/MixerView.qml` (island view `mixer`, `ipc call island open mixer`): output slider with the device name, one slider per app stream (app icon, name · media title, mute on the icon), mic slider, then the `AudioDevices` pickers; ↑/↓ select, ←/→ adjust, M mutes. Opened by right-clicking the Control volume slider or the volume pill icon. Also: right-click the network/Bluetooth pill icons → their Control pages (`UiState.openControl()`; the open page now lives in `UiState.controlDetail`), right-click the mic slider → sound devices. The overlay mixer card uses `Audio.streams` / `Audio.appName`
  - Verified with a silent `pw-play` stream: its row appears, ←/→ on it changes only the stream (90) while the output stays 100; pill right-clicks open the mixer and Network; the overlay card still loads (grim)
- [x] Motion pass: no restart-from-zero animations, retargeting press squash, tune `bouncy` damping, shared `components/Reveal.qml`
  - `components/Reveal.qml` replaces the island's `ContentReveal`, the Control page fade and the settings page fade: fade + spring scale, and only a new target starts hidden, so replaying on the same item carries on instead of jumping to 0
  - `MaterialShape`: a shape change mid-morph waits until the running morph is 97 % done instead of restarting from its old start (the vendored morph only runs between whole shapes)
  - `PressButton`: the squash (scale 0.94, corners 80 %) holds at least 90 ms, so a quick click still shows it; the spring retargets from wherever it is
  - `bouncy` damping 0.26 → 0.36. Simulating Qt's SpringAnimation update rule: 17 % overshoot, still moving after ~540 ms → ~4 % and ~420 ms, close to Hyprland's `bouncy` curve (damping ratio 0.70). smooth/snappy/gentle already do not overshoot
  - Also fixed: `DetailRow`'s busy pulse animated `opacity` directly, so it could freeze half-faded when busy ended; it now drives a separate value
  - Verified: view switch frames (shape springs, content fades in behind it), fast workspace flicks 1 → 2 → 3 (grim); install --check ok, no config errors, 201 binds. The press squash was not caught on a frame → hands-on feel check

- [x] Fix: the shell crashed when the island opened (added 2026-10-03)
  - Cause: `components/Reveal.qml` (motion pass) put a `SpringAnimation` inside an animation group; Qt segfaults starting it there (`QQuickSpringAnimation::transition` → `QQmlProperty::name`, 3 core dumps). Its scale step is now a `NumberAnimation` (OutBack), as `ContentReveal` had; no other SpringAnimation sits in a group. Verified: every island view, a Control detail page and the settings app open with no new core dump
- [x] Fix: the hover peek never showed over a maximized window (added 2026-10-03)
  - Cause: Hyprland's `hasFullscreen` is also true for maximize (fullscreen mode 1). The island now blocks the peek only when a toplevel on the workspace is really fullscreen (`wayland.fullscreen`). Verified: peeks over maximized kitty, not over a fullscreen (mode 2) one
**9e. Media and lyrics**
- [x] `services/Lyrics.qml`: LRCLIB via curl on track change, cached in `~/.cache/somehypr/lyrics/`, synced LRC, `media.lyrics` toggle
  - One `sh` + curl per new track (400 ms debounce): `/api/get` (title, artist, duration), then `/api/search`, best result = synced first, then the closest length. Any 200 is cached per track (an empty search `[]` is a cached miss); network errors are not cached. Browser titles are cleaned ("Artist - Title (Official Video)", "- Topic", VEVO)
  - LRC parsed to `lines` (several stamps per line handled), `plain`, `status` (off/loading/synced/plain/none/error). The current `index` follows the playhead with one single-shot timer aimed at the next line, only while a view raises `Lyrics.watchers`; seeks resync through the player's position signal
  - Settings → Island → Lyrics; `ipc call lyrics state` / `retry`
  - Verified with a fake MPRIS player (`gi` test script, not shipped): Bohemian Rhapsody → synced 56 lines on the right line 65 s in; "Queen - Don't Stop Me Now (Official Video)" with no artist → found; an unknown track → `none`, cached as `[]`
- [x] MediaView: lyrics pane and per-player volume (MPRIS volume, or the PipeWire stream)
  - `components/LyricsPane.qml` (pure view, reused by the widget): synced lines in a ListView that keeps the current one centered (brighter, title weight, springs to 1.06), earlier lines dimmer; click a line to seek there; plain lyrics scroll; loading / none / error (click retries) messages. Opens at the current line, not the top
  - The pane sits under the controls (island grows by ~200 px), loaded only while shown; the lyrics button (or L) hides it (`media.lyricsPane`). The view raises `Lyrics.watchers` only while the pane is up
  - `Media.stream` matches the player's Pipewire stream (pid from `…instance<pid>` in the bus name, else binary / app name vs bus name, desktop entry, identity); `Media.setVolume` uses it, else MPRIS `Volume`. Streams are bound only while a media view watches (their properties are empty until bound). Slider under the controls, +/− keys, the icon mutes
  - Verified with the fake player (grim): the pane opens on the right line and follows it, an external seek (`playerctl position 200`) and a click on a line both resync; the slider sets MPRIS volume (0.38); with a silent `pw-play` named like the player it sets the stream instead (0.52 → Pipewire 0.143 cubic) and leaves MPRIS alone; the toggle shrinks the island
- [x] Ambient/peek lyric line (optional); MediaWidget lyrics and volume
  - Collapsed island: with `media.ambientLyrics` (off by default; Settings → Island → Lyric line in the island) the media state shows the current synced line instead of title · artist (up to 320 px), fading out, swapping, fading in; falls back to the title on instrumental gaps. `Lyrics` is not even created while the option is off. The peek is the media view, which already has the pane
  - Desktop widget: the player's volume slider under the controls and three synced lines (`LyricsPane`, click seeks) when lyrics are found (`media.widgetLyrics`, Settings → Desktop); the line follows only while the widget is visible (same `live` gate as its progress). `Slider` gained `contentColor`/`contentDim`/`contentOnFill` for the widget's own colors
  - Fixed on the way: the swap used a `PropertyAction` whose value is read at `restart()`, so the island lagged one line behind; now a `ScriptAction`
  - Verified with the fake player (grim): the island line matches `ipc call lyrics state` line by line, toggling the option live adds/removes the watcher; the widget in edit mode shows the slider and lyrics; settings rows render; install --check ok, no config errors, 201 binds

**9e+. Media and island fixes** (added 2026-10-03, on request)
- [x] Media view: the player chips overlap the title
  - The chips and the lyrics button now sit in the title row (chip names capped at 84 px) and the title elides in the space left. Verified with Brave + Plasma browser integration (grim)
- [x] Album art sometimes missing (browser players)
  - Cause: Brave shows up twice (its own MPRIS without art, and Plasma browser integration, which downloads the art to a temp file and sometimes leaves it out, e.g. on YouTube Music). `Media.art` now falls back to another player of the same process (`kde:pid` / `instance<pid>`), then to the YouTube thumbnail of `xesam:url` (`i.ytimg.com/…/mqdefault.jpg`, 16:9 without bars). `Cover` retries a failed load 3× (700 ms), for art files announced before they are written
  - Verified over IPC: the art-less Brave player resolves to its sibling's file, a fake player with only a music.youtube.com URL to the thumbnail; Qt loads the https thumbnail (offscreen test)
- [x] Dock: a half-screen flicker when it hides after a peek
  - Cause: the blur gate (`bg.y < height - 1`) let the region through for ~1.5 px of the slide where the inset, rounded region (`ceil(y) + 1`) already lay below the surface; the compositor reads that as empty and blurs the whole 420 px dock surface for a frame (the Phase 4 gotcha). The gate now keeps a 4 px margin; the island, pills and OSK had the same edge and got the same margin
  - [ ] Hands-on check by you: peek the dock over a window and let it hide (not reproduced here without taking over the pointer)
- [x] Clicking outside the island closes it
  - Cause: the open island took `Exclusive` keyboard focus, and Hyprland never moves focus away from an exclusive layer, so a click elsewhere never cleared the focus grab (the "not new" note in 9d). It now starts `Exclusive` (typing right after Super still lands in search) and switches to `OnDemand` once the grab is active (50 ms), as ii's overview did
  - Verified: a click on a window outside closes the island (grab cleared); → keys after the switch still change views

**9f. Game overlay and live translator**
- [x] Overlay style settings (glass/solid/minimal, opacity, accent, radius, compact) under `overlay.style`
  - `overlay.style` { look, opacity, accent, radius, compact }, Settings → Modes → Overlay style (segmented look, opacity slider, accent swatches with "Theme", corner radius, compact). Glass = tint + rim + frost (the frost switches show only for glass, and Hyprland's game-mode blur is asked for only then); solid = no blur, tint at the opacity; minimal = faint backing, no rim, outlined titles
  - Accent colors the card icons, the toolbar's active buttons, pin, crosshair toggles and FPS presets (dark content on custom accents; `Toggle.activeFg` added). Compact: 32 px title bars (24 pinned), 10 px padding
  - Verified live over the open overlay and pinned cards (grim): glass, solid + yellow + 8 px + compact, minimal + cyan open and pinned; settings page loads with no warnings
- [x] Live area translator (`overlay/TranslateCard.qml` + `services/LiveTranslate.qml`): pick an area once; re-run OCR and `trans` only when the pixels change, with one chain at a time; stops on unpin
  - `services/LiveTranslate.qml`: area in `overlay.translateArea` (layout px). Every 1.5 s, only while the card exists, the overlay is closed and not paused, one chain at a time: grim → 64×24 posterized gray thumbnail → md5; unchanged pixels stop there. Changed → grim → 2× gray → tesseract (all installed languages); unchanged text stops there. Changed → `trans` into `capture.translateTo`. A failed translation retries on the next tick
  - `overlay/TranslateCard.qml`: translation (outlined, larger when pinned), source text, "New area", language cycle (ไทย / English / 日本語, re-translates the current text), pause, copy; the area is outlined while the overlay is open; a warning when the card covers the area (grim sees the overlay too). Picking an area pins the card and places it just below the area (or above), never over it; closing or unpinning stops everything
  - Found and fixed: several Config writes in one handler lost some of them, because the file watcher reloaded config.json after our own first write and undid the later ones. `Config` now ignores file changes within 600 ms of its own write
- [x] `/translate live` command and an overlay card entry
  - `/translate live` (suggested after `/translate`), `ipc call livetranslate pick|state`, a "Live translate" mode in the region picker (key 7), and the overlay toolbar button (key 7) for the card
  - Verified with a real drag in the picker over a kitty window: English → Thai, an edited line re-translated within a tick, nothing runs while the overlay is open, unpinning → `stopped` with no grim/tesseract left (grim)

**9g. Widgets and lock polish**
- [x] Lock dots: only the added or removed dot animates; smooth clear after the shake
  - Done in 9b+ (password shapes)
- [x] New widgets: wallpaper, gallery, calendar, weather, lyrics, quick launch
  - Calendar (locale's first weekday, today as a cookie shape, ‹ › months, minute clock only), Weather (`services/Weather.qml`: Open-Meteo, place from `widgets.weatherCity` or a rough IP location via ip-api.com, °C/°F, one curl chain at start and every 30 min, only while the widget is on), Wallpaper (thumbnail, shuffle, light/dark, picker), Gallery (FolderListModel over `widgets.galleryDir`, default ~/Pictures; crossfade every `widgets.galleryInterval` s only while the desktop is visible; images decoded at widget size; click next, double-click opens), Lyrics (five synced lines, outlined when unframed; the line follows only while visible), Quick launch (most used apps by search frecency, topped up with the dock's pinned apps, eight at most)
  - Settings → Desktop lists them all, plus weather place/units and gallery folder/speed (shown while that widget is on)
  - Fixed on the way: the widgets' frost used `item:` regions on the card, so it lagged behind a dragged widget (same as the overlay cards); each region is now built from the widget's x/y
  - Verified with all ten on in edit mode (grim): weather found Uttaradit 31 °C with a 3-day forecast, calendar marks today, gallery crossfades on a 5 s test interval, frost follows a dragged widget; your widget setup was restored afterwards
- [x] Game overlay lyrics card: the playing track's synced lyrics on screen over the game, pinnable click-through (added 2026-10-03)
  - `overlay/LyricsCard.qml` (toolbar button, key 6): open, it shows the track (art, title, artist), previous / play-pause / next and five lines (`LyricsPane`, click seeks); pinned over a game, three larger lines with a dark glyph outline (`LyricsPane.outline`) so they read over anything. Messages for lyrics off, nothing playing, loading, none, error (click retries). Raises `Lyrics.watchers` only while the card exists
  - Verified with a real YouTube Music track in Brave (Aimer "Ito", synced Japanese lyrics): card opens with the overlay, pin by click, overlay closed → the card stays, follows the song, and a click on it lands on the window below (grim)
- [x] Overlay cards: the frost does not follow a dragged card; pinned cards are not frosted after the overlay closes → fix, plus options to frost cards while open / while pinned (added 2026-10-03)
  - Cause of the trailing frost: `Region { item: card.frost }` only updates when the frost item's own geometry changes, not when its card is dragged (same as the pills in 9d). Each card's region is now built from the card's window x/y (`CardRegion` in `GameOverlay.qml`)
  - Options (Settings → Modes → Game overlay): Frosted glass (`overlay.blur`, default on: bar and cards blurred while open, solid when off) and Frost pinned widgets (`overlay.pinnedBlur`, default off: pinned cards keep their blur after closing). In game mode Hyprland's blur stays on while either needs it (`GameMode.overlayBlur` → `GameMode.overlay()`); the cost is the blur passes under the cards only
  - Verified with real drags (ydotool relative moves; a `cursor.move` warp sends no drag motion): frost stays under the lyrics card mid-drag and after; pinned + option on → frosted after closing and `GameMode.overlay_open` true, option off → translucent and false (grim)
- [x] Hotfix: the hold-to-confirm animation on the island power buttons looked cheap (added 2026-10-03)
  - Before: a separate rounded blob with a fixed red and its own radius grew linearly from the bottom, unclipped and not following the button's corner morph
  - `PressButton.progress` / `progressColor`: a fill clipped to the button's own shape (straight level, rounded bottom, follows the squash), drawn under the content. PowerView rises it with InOutSine over 650 ms, drains it with OutCubic on early release, swells the icon with the fill; a confirmed action gets a 240 ms beat (solid button, icon pop) before the island closes
  - Verified with grim: partial hold and drain on the live shell; full hold in a scratch copy with the session actions replaced by logs (fires once)

- [x] Verify: the CLAUDE.md checks (201 binds, no WARN/ERROR), grim checks (edges over a bright window, no tile flicker while recording, lock dots), memory and CPU against Phase 8, game mode
  - Config: `install.sh --check` ok, no config errors, 201 binds; no WARN/ERROR from the shell or the settings app (only the known Hyprland IPC "openwindow … not previously tracked" line)
  - Memory (live shell restarted for a clean read; it had been hot-reloaded dozens of times and sat at 342 MB anon): fresh 437 MB RSS / 294 MB PSS / 180 MB anon with music playing (Phase 8: 414 MB RSS, ~170 MB anon); after opening every island view, the overlay, the overview and widget edit mode: 493 MB RSS / 206 MB anon (Phase 8 after use: ~210 MB anon)
  - CPU over 60 s: 0 % idle with media hidden in the island (same as Phase 8); 2 % while music plays, from the island's live peak bars (visible, so allowed by the targets). Only child process: the gamemoded `gdbus monitor`
  - Game mode (forced on, then back to auto): blur, shadows and animations off, island → dot, dock and widgets unloaded, mpvpaper paused (mpv IPC `pause` true → false), the overlay turns blur on only while open; everything restored after
  - grim: the open island over a white window has smooth corners, no stair steps or wallpaper at the edge; 12 frames of the Control view while recording (timer ticking) are identical in the tile grid; lock preview: 5 typed → 5 shapes, 2 backspaces → 3
  - Seen once, not reproduced: the lock preview did not get the keyboard until clicked (3 later tries took it at once)
- [ ] Hands-on check by you: feel of the hover peek, glass over real windows, lyrics, live translator in a game

### Phase 10: Fixes and improvements ✅ (brightness, binds, wallpaper schedule, quick options)
From your request (2026-10-03). Commit and push per task, as in Phase 9.

Starting points found while planning:
- Brightness: `services/Brightness.qml` is DDC/CI only. It runs `ddcutil detect --brief` once at start and writes with `setvcp 10`, and the Control slider shows only while `Brightness.available`. Nothing is logged when ddcutil fails.
- Super+Alt+N: `binds/keybinds.lua` (send to workspace N) calls `hl.dispatch(hl.dsp.window.move({ workspace = …, follow = false }))` from a Lua function, with no window target.
- Wallpaper: `services/DayNight.qml` has two phases (day/night: `theme.schedule` dayStart/nightStart, dayFolder/nightFolder, modes, night light) and picks one random wallpaper per switch. `services/Weather.qml` already uses Open-Meteo, which also gives sunrise and sunset.
- Quick options: `services/QuickTiles.qml` + `island/views/TileGrid.qml` (`control.tiles`, one global `control.tileStyle`). The volume, mic and brightness sliders are fixed below the grid in `island/views/ControlView.qml`.

**10a. Fixes**
- [x] Brightness in the island cannot be changed
  - Cause: `ddcutil detect --brief` lists an "Invalid display" first (i2c-1, the monitor's HDMI input, no DDC), and the regex took the first bus, so every setvcp went to i2c-1 and failed with EIO. Permissions and `i2c-dev` were fine
  - `services/Brightness.qml` parses each detect block, skips invalid ones and keeps `{ bus, connector }`; the bus follows the focused monitor's connector (first valid display otherwise) and re-reads the level when it changes. A failed write logs once and re-reads the real level
  - Verified: `ipc call brightness set 30/60/5` and `increment` → `getvcp` on i2c-2 reads the same value; the Control slider shows the monitor's level (grim). A set right after a shell reload, before detect finishes, only moves the slider until the read-back
  - Follow-up: the read-back never ran, so the slider stayed at 50 % while the monitor was at 5. In `onBusChanged`, `available` and the getter's bound command had not caught up with the new bus yet; `read()` now checks `bus` itself and sets the command. Verified: the slider shows 5 after a reload (grim)
- [x] Super+Alt+N moves every window; it should move only the focused one
  - Cause: on the US layout a digit press matches both the key-name bind (`SUPER + ALT + 1`) and the Thai-layout keycode bind (`code:10`), and Hyprland runs both. The first moved the focused window, focus passed to the next window, and the second moved that one too. Verified with two test binds on one key (both fired). The dispatcher alone moves only the focused window. `hyprctl binds` shows `keycode: 0` for `code:N` binds, but they do match
  - `binds/keybinds.lua`: the send and focus actions are wrapped in `once_per_press()` (a guard cleared by a 50 ms one-shot `hl.timer`), so one press runs once. Binds, descriptions and remaps are unchanged
  - Verified with two throwaway windows on workspace 18: Super+Alt+9 moved only the focused one to 19, keypad Super+Alt+7 → 17, Super+9 focuses 19; install --check ok, no config errors, 201 binds

**10b. Wallpaper engine: time-of-day schedule**
- [x] Five slots: sunrise, noon, sunset, night, midnight. Each one can be on or off and has a start time, a source, a light/dark mode and night light on/off
  - Sources: one wallpaper (image or video), a folder (one random pick when the slot starts), or **dynamic** (a random re-pick from a folder every N minutes while the slot lasts)
  - `theme.schedule.slots`. The old day/night values are migrated, day → sunrise and night → night
  - [~] Mode and night light are each keep / one of the values, so a slot can leave them alone. Not migrated by a write: `lib/schedule.js` builds the slots from the day/night keys while `slots` is empty (night light: on at night and off at sunrise only if the old switch was on), and the saved phase `day` counts as `sunrise`, so an old setup does not re-apply after the update
- [x] Optional sun times: sunrise and sunset from Open-Meteo (Weather's place), noon and midnight derived from them, and a ± minutes offset per slot. Fetched once a day, only while the option is on
  - Noon = solar noon (midpoint), midnight = noon + 12 h, night = sunset + 1 h, then each slot's offset. The location step is shared with Weather (`Weather.locate`); the result is cached in `~/.local/state/somehypr/sun.json` per day and place. Without an answer the slot times are used (one warning)
- [x] `services/DayNight.qml` → a slot scheduler. It keeps the single minute clock, gated on enabled. The dynamic timer exists only in a dynamic slot and pauses in game mode. Picks go through `Wallpaper`, so videos still get mpvpaper and a matugen frame
  - `services/Schedule.qml` (DayNight removed); the model is the pure `lib/schedule.js`, used by the settings page too, so the settings process never runs a second scheduler. It waits for `Wallpaper.loaded` before its first check
  - Found and fixed: the old DayNight could check before the wallpaper state was read and save an empty path over it (it happened once during this work; your wallpaper was set back). `Wallpaper.save()` now refuses to write before `loaded`
  - Found and fixed: `rotate.restart()` broke the timer's `running` binding, so the rotation kept going in later slots; the binding alone drives it now
- [x] Settings → Wallpaper: slot editor (timeline bar, source picker per slot, interval, mode, night light) and "Preview this slot". IPC `wallpaper slot <name>` for tests
  - Time of day section: schedule switch, Follow the sun (shows today's times), a 24 h bar with one band per slot and its start, then one row per slot (summary, start time or ± offset with the sun, on switch, expand). Expanded: Keep / File / Folder / Dynamic, file or folder chooser (kdialog), Change every (min), Colors keep/dark/light, Night light keep/on/off, Preview. A preview holds until the next slot starts
  - Also `ipc call schedule state` and `schedule at <HH:MM|now>` (test a time of day)
- [x] Verify: step through every slot over IPC, check that the dynamic re-pick happens and stops at the slot edge, and compare memory with the rotation running
  - Test slots over a scratch folder: 12:55 → noon (dynamic, 1 min) picked from the folder and re-picked after a minute; `at 18:30` → sunset set its file and the rotation stopped; preview night held through 18:45 and the 20:05 start cleared it; 03:00 → midnight (wraps past 00:00). Game mode forced on → rotation paused, auto → resumed. Sun times: 06:10 / 18:06 for the IP location, noon 12:08, midnight 00:08, night + 30 min offset → 19:36. A click in the editor wrote `slots.noon.source` and the shell followed. Your schedule, wallpaper and dark colors were restored afterwards (shell restarted so it resumed from the saved phase)
  - Memory with the rotation: moved to the Phase 10 check
  - Seen once: after forcing game mode on and back to auto, the shell kept the game-mode dot while Hyprland had it off; a second try matched. Not reproduced

**10c. Quick options: per-tile style and movable sliders**
- [x] Style per tile: full (icon + text) or icon only. The global `tileStyle` becomes the default, and edit mode changes one tile. The grid packs mixed sizes, and the stable delegates still spring to their slots
  - `control.sizes` (id → full/icon) over `control.tileStyle`; `QuickTiles.size/setSize`. Edit mode: a size badge in each tile's lower-left corner. The grid button sets every tile to one size and clears the per-tile ones (`setAllSizes`)
  - `TileGrid` flows items on 8 units per row (icon 1, full 4, slider 8); an item that does not fit starts the next row, rows take their tallest item. Width, x and y spring as before, still one delegate per id (now a Loader: Toggle or Slider)
- [x] Volume, mic and brightness sliders join the same layout (`control.tiles` entries like `slider:volume`): they can be dragged to reorder and hidden or shown in edit mode, and ↑/↓/←/→ follow the new order
  - [~] Stored in a new `control.layout` instead of `control.tiles`: while it is empty, the layout is `tiles` + the three sliders, so saved setups keep their look with no migration write. `QuickTiles` has `SliderItem`s (icon, value, set, icon click, right-click: volume → mixer, mic → sound devices); brightness is unavailable without a DDC monitor. Saves keep unavailable items in place
  - Drag targets come from the packed slots (the item under the pointer), so mixed sizes reorder correctly. The fixed sliders are gone from `ControlView`; keys go through `TileGrid.isSlider/run/adjust`. Edit badges are now solid, so they read over a slider's light fill
- [x] Verify with real clicks (grim): mixed sizes, a slider dragged above the tiles, a hidden slider, no recreated delegates while recording
  - Verified by clicks and ydotool drags: DND → icon (Game mode slid beside it), volume dragged to the top (others slid live, saved on release, volume unchanged), the mic slider hidden (mic level unchanged), grid button → all icons, ↓ + ←/→ on the top slider changed the volume 1.00 → 0.95 → 1.00, ↓ + Enter on Network opened its page. Your layout was restored afterwards
  - The recording check was not repeated: tiles still have one delegate per id bound to their own properties (unchanged from 9d)
  - Also fixed on the way (10a): the brightness slider showed 50 % because its read-back never ran

- [x] Verify Phase 10: the CLAUDE.md checks (201 binds, no WARN/ERROR), memory and CPU against Phase 9, game mode
  - Config: `install.sh --check` ok, no config errors, 201 binds; no WARN/ERROR from the shell or the settings app (only the known "openwindow … not previously tracked" line)
  - Memory, fresh shell: 442 MB RSS / 255 MB PSS / 179 MB anon (Phase 9 fresh: 437 / 294 / 180). After six wallpaper swaps through the shell (what a dynamic slot does): 464 / 273 / 193; a seventh swap added nothing, so it levels off instead of growing per swap
  - CPU over 60 s idle: 0 % (Phase 9: 0 %). Only child process: the gamemoded `gdbus monitor`
  - Game mode forced on: blur, shadows and animations off, island → dot, schedule rotation paused; auto restored all of them
- [ ] Hands-on check by you: brightness slider and keys, Super+Alt+N with a few windows, editing the quick options by hand, a real day with the time-of-day schedule (and Follow the sun)

### Phase 11: Optimize, polish and public release
From your request (2026-10-03). Runs after Phase 10.

**11a. Optimize and polish**
- [ ] Profile pass: anon/PSS and idle CPU against Phase 9, frame times of island morphs (`debug:overlay`), heaptrack if installed. Remove dead code and unused config keys, and lazy-load anything that still loads eagerly
- [ ] Polish pass: fix the visual and motion rough edges from daily use and the open hands-on checks of Phases 7–9

**11b. Public repo layout**
- [ ] Move `idea.md` and `Improvement idea.md` to `docs/ideas/`, and update the links in CLAUDE.md and this plan
- [ ] Rewrite `README.md` for other people: screenshots, features, requirements (Arch/CachyOS, Hyprland 0.56 Lua, Quickshell), install, update, uninstall/rollback, configuration, credits and licenses (the vendored shapes are Apache-2.0, plus the fonts). Add `docs/` pages for architecture, settings and troubleshooting, and a LICENSE
- [ ] Remove machine-specific values: DP-1 / 1920x1080@100, the NVIDIA env, UGTablet, the US/TH layout and the weather place are detected or become settings. `hypr/monitors.lua` is generated and gitignored, with a default. No personal paths or names in the tracked files

**11c. Installer for other PCs**
- [ ] Bootstrap in `install.sh` (or a `setup.sh` that calls it). It does the following:
  - Checks dependencies and installs the missing ones with pacman/paru: Hyprland, quickshell, matugen, grim, wf-recorder, ddcutil, tesseract, translate-shell, ydotool and the fonts. The fonts must not depend on ii's package
  - Detects the GPU (NVIDIA env only when needed) and the monitors (writes monitors.lua)
  - Backs up existing configs (`.pre-somehypr`)
  - Runs a first matugen pass
  - Sets up ydotoold and the i2c group
  - Keeps `--check` and `--rollback`
- [ ] Test on a clean user or a VM (a nested Hyprland does not cover the installer), and document it in the README

- [ ] Verify Phase 11: a fresh install from a clone works, rollback works, the CLAUDE.md checks pass

## Verification
- **Hyprland:**
  - `hyprctl configerrors` is empty.
  - `hyprctl binds -j | jq length` is 201 when `keybinds.json` adds nothing (ii's 191, plus 10 Thai keycode binds and the record-submap escape, minus ii's panel-family and welcome binds, plus CLI fallbacks for the two screen-record actions; the wallpaper picker lost its ii `switchwall.sh` fallback in Phase 8).
  - Spot-check options with `hyprctl getoption`.
  - SUPER+ALT+N works with the TH layout active.
- **Shell:**
  - `timeout 12 qs -c somehypr 2>&1 | grep -E "WARN|ERROR"` shows no new ReferenceError or TypeError.
  - Every view can be opened through `qs -c somehypr ipc call island open <view>`.
- **Performance:**
  - `ps -o rss,pcpu -C qs` after 10 min idle, plus `Anonymous`/`Pss` from `/proc/<pid>/smaps_rollup` (RSS alone counts shared libraries and every font mapping; see Phase 8).
  - `pidstat -p $(pidof qs) 1 60` averages about 0%.
  - Hyprland `debug:overlay` shows frames under 10 ms during island morphs.
  - `QSG_RENDER_TIMING=1` for scene-graph cost.
- **Game mode:** launch a Steam game and check that blur, shadows and animations are off, mpvpaper is paused and the island is a dot. After exiting, everything is restored.
- **Rollback drill:** `install.sh --rollback && hyprctl reload` brings back the exact ii setup (`~/.config/hypr.pre-somehypr` and `~/.config/quickshell/ii` are kept for this).
