# SomeHypr

Personal Hyprland desktop for one machine: CachyOS, Hyprland 0.56 (Lua config), RTX 3060, one 1920x1080@100 monitor (DP-1), US/TH keyboard, UGTablet pen.
Goals are in `idea.md`. The full plan, with phases and targets, is in `docs/plan.md`.

## Layout
- `hypr/` is linked to `~/.config/hypr`. `hyprland.lua` loads files in a fixed order, and each setting lives in exactly one file:
  - `user.lua` holds user choices: apps, `glass`, `liquidGlass*`, `gameModeAuto`. The settings app overrides them through `~/.config/somehypr/hypr.json` (`SETTINGS`, loaded by `lib/util.lua` with `lib/json.lua`); `core/settings.lua` loads last and applies its `hyprland` table (a partial `hl.config`). The file only holds changed values.
  - `core/` covers env (NVIDIA), input and tablet, look, motion, misc, and execs.
  - `rules/` holds window rules (windows, media, art, gaming) and layer rules.
  - `binds/keybinds.lua` holds every bind. Shell binds go through `shell_bind()` / `SHELL_ACTIONS` in `binds/shell.lua`: a `somehypr:` global shortcut plus an optional CLI fallback that runs only while the shell is not answering.
  - `binds/user.lua` applies `~/.config/somehypr/keybinds.json` (settings app): it wraps `hl.bind` while keybinds.lua runs (remap/disable by normalized combo), then `UserBinds.finish()` adds custom binds and the `somehypr-record` submap. User changes never go into keybinds.lua.
  - `core/liquidglass.lua` is the optional hyprglass plugin (`liquidGlass`). Build with `scripts/hyprglass.sh` (upstream branch + `plugins/hyprglass-fit-shape.patch`, one `.so` per Hyprland version in `~/.local/share/somehypr/plugins/`). `hl.plugin.load()` is declarative: call it on every config load while the plugin is wanted, never only "if not loaded" (that loops unload/load/reload until Hyprland segfaults). Test plugin changes in a nested `Hyprland -c <test.lua>` first.
  - `modes/gamemode.lua` turns blur, shadows and animations off while a game is the focused fullscreen window. Control it with `hyprctl eval 'GameMode.toggle()'` and `'GameMode.auto()'`.
  - `generated/` is machine-written (matugen) and gitignored. `monitors.lua` is written by the display settings page.
- `matugen/` is linked to `~/.config/matugen` and is the only color engine. `config.toml` lists every output (shell, Hyprland, terminals, GTK, KDE, fuzzel, Zen, Vesktop); `hooks/` reload apps. Run it without a terminal only with `--source-color-index 0`.
- Wallpaper state is `~/.local/state/somehypr/wallpaper.json`; set it through the shell (`qs -c somehypr ipc call wallpaper set <path>`) so videos start mpvpaper and get a matugen frame. Images are shown from a screen-sized copy (`~/.cache/somehypr/wall-<WxH>-<md5>.jpg`, ImageMagick), because Qt keeps a large original's full decode in memory.
- `shell/` is linked to `~/.config/quickshell/somehypr` and runs with `qs -c somehypr`:
  - `core/` singletons (Config, Theme, Motion, Paths, UiState, GameMode), `components/`, `services/` (one singleton per system source).
  - `island/Island.qml` is the notch window; `island/views/*View.qml` are loaded only while open; `island/ambient/` holds the collapsed states.
  - `commands/` holds one file per `/command`, registered in `commands/Commands.qml`.
  - `Shortcuts.qml` (global shortcuts) and `Ipc.qml` (IPC targets) sit at the root; `corners/` holds the pills: `PillParts.qml` defines each part (a `PillPart`, glass or floating per `config.json` `pills`), `Pills.qml` creates a `CornerWindow` per zone (corners or beside the island, `pills.layout`), which joins neighboring glass parts into one pill and `wallpaper/` the background layer.
  - `settings.qml` + `settings/` is the settings app, a separate process (`qs -c somehypr ipc call settings open` or `settings page <id>`; a second call focuses the running one). `settings/` holds its stores (HyprSettings, KeybindStore, ShellIpc), `ui/` and one file per page in `pages/`. It changes shell state over IPC, never by running a second copy of a service.
  - `capture/RegionSelector.qml` is the region picker over a grim-frozen frame; `services/Capture.qml` runs the tools and `services/Recorder.qml` owns wf-recorder (the island shows the timer).
  - `overlay/` is the Super+G game overlay (one card file per widget). Its cards are frosted over the game itself (shell layers have no `xray`); game mode turns compositor blur back on only while it is open (`GameMode.overlay()` in `modes/gamemode.lua`).
  - `services/Streamer.qml` is streamer mode; peeks then go to `island/PrivatePeek.qml` on the `somehypr:private` layer (`no_screen_share`). `services/GameClients.qml` feeds gamemoded PIDs to `GameMode.set_clients()`.
  - `lock/` is the lock screen (`WlSessionLock`, surfaces only while locked); state and PAM live in `services/Lock.qml`. `hypr/scripts/lock.sh` calls `ipc call lock lock` and runs hyprlock when the shell does not answer. There is no unlock IPC; test with `ipc call lock preview` (no PAM, Esc closes).
  - `widgets/` holds the desktop widgets (bottom layer, one window per screen, hidden in game mode); `services/Widgets.qml` lists them, `config.json` `widgets` stores which are on and where. Edit mode: `ipc call widgets edit`.
  - `osk/` is the Super+K keyboard; `services/VirtualKeys.qml` types through ydotoold (`YDOTOOL_SOCKET` is passed per call, the shell's env lacks it).
  - `dock/` is the bottom dock (contents from `services/Taskbar.qml`, settings under `dock` in config.json). `overview/` is Super+Tab, created only while open.
  - Glass: `components/Glass.qml` (tint + rim + highlight, tokens `Theme.glass*`, `Config.glass`) with its blur from `GlassRegion` (direct window children) or `Region { item: g.frost; radius: g.frostRadius }`. The region stays 1 px inside because Wayland regions have whole-pixel stepped corners. Gate blur on `Theme.blur` (glass on and not game mode).
  - Expressive style: `components/MaterialShape.qml` (35 Material 3 shapes from `lib/shapes/`, drawn with QtQuick.Shapes, never Canvas), `ShapeIcon.qml` (floating icon, shape when active); `PressButton` `radius`/`activeRadius` morph on a spring. Text weights come from `Theme.font.weight`/`weightTitle` through `font.weight`, not `variableAxes`.
  - Blur gotcha: an empty `BackgroundEffect.blurRegion` blurs the whole surface, so set it to `null` whenever the shape is off-surface Gate with a few px of margin: the region is inset and rounded, so it leaves the surface before the item does.
  - Focus gotcha: a layer with `Exclusive` keyboard focus keeps it, so a `HyprlandFocusGrab` never clears on an outside click; switch to `OnDemand` once the grab is active (`island/Island.qml`).
  - QML gotcha: a property named `onX` is parsed as a signal handler, so theme colors use `fgX` (e.g. `Theme.fgIsland`).
  - Animation gotcha: `SpringAnimation` (and `Spring`) only in a `Behavior` or as `SpringAnimation on <prop>`. Inside a `Sequential`/`ParallelAnimation` Qt segfaults when it starts; use `NumberAnimation` there (`components/Reveal.qml`).
  - Font gotcha: every distinct `font.variableAxes` value opens another face (mmap + glyph cache). `components/Icon.qml` snaps FILL to 0/1 and opsz to 20/24/40/48; never animate an axis.
- `install.sh` links everything and reloads, rolling back automatically if there are config errors. `--check` only verifies; `--rollback` restores `~/.config/*.pre-somehypr`.

## Hyprland Lua API
- The authoritative stub is `/usr/share/hypr/stubs/hl.meta.lua`: events, rule fields, config keys and dispatchers. Example config: `/usr/share/hypr/hyprland.lua`.
- Window and layer rules take effects as flat fields, e.g. `hl.window_rule({ match = {...}, no_blur = true })`. Unknown fields are config errors.
- Springs: `hl.curve(name, { type = "spring", mass, stiffness, dampening })`, used as `spring = name` in `hl.animation`.
- Runtime: `hyprctl eval '<lua>'` runs code, and `hyprctl repl 'return <expr>'` reads Lua globals (e.g. `GameMode.active`).

## Verify every change
```sh
./install.sh --check                 # Hyprland --verify-config on the repo config
hyprctl reload && hyprctl configerrors   # live; must print nothing
hyprctl binds -j | jq length         # 201 (with no keybinds.json)
```
Shell changes:
```sh
timeout 10 qs -p shell/shell.qml 2>&1 | grep -E "WARN|ERROR"   # dev copy; only notification/polkit clashes with the live shell may appear
qs -c somehypr ipc call island open <view>                     # search control media notifications system power clipboard emoji keys
qs -c somehypr ipc call island state
qs -c somehypr ipc call overview toggle
qs -c somehypr ipc call capture region <mode>                   # shot ocr lens translate record recordSound
qs -c somehypr ipc call overlay toggle · streamer toggle
qs -c somehypr ipc call lock preview · widgets edit · osk toggle
timeout 8 qs -p shell/settings.qml 2>&1 | grep -E "WARN|ERROR"   # settings app
```
- IPC function names must not clash with `qs ipc` subcommands (`show`, `call`, `prop`): `qs ipc call x show` is parsed as `qs ipc show`.
Never edit `~/.config/hypr.pre-somehypr` or `~/.config/quickshell/ii`. They are the rollback (`install.sh --rollback`).
- Memory: compare against a fresh start and read `Anonymous`/`Pss` in `/proc/<pid>/smaps_rollup`, not only RSS. An empty one-window Quickshell already shows ~250 MB RSS / ~55 MB anon on this NVIDIA stack. Measure with `pgrep -x qs`; `pkill -f "qs -c somehypr"` also matches the shell running the command.

## Phase workflow
- Work through `docs/plan.md` one phase at a time and tick its checkboxes (`[x]` done, `[~]` done differently, with a note) as tasks land.
- Commit and push after **each task** (one checklist item, or one small sub-phase), once it is verified: tick it in `docs/plan.md` in the same commit, then `git push origin main` (remote `someact/SomeHypr`, private). Message: `Phase <n><sub>: <task>` (e.g. `Phase 9c: show only occupied workspaces`). Unrelated changes go in their own commit.
- When the last task of a phase is done and the phase-level checks pass, mark the phase ✅ in the plan in that final commit.
- New tasks the user asks for mid-phase go into the plan first (as a `9a+`-style section, dated), so every change is tracked.
- `README.md` explains how the setup works, installs and updates. Update it in the same commit when a change affects any of those (new dependency, script, option, or install step).

## Rules for the shell (Phase 2 onward)
- Lazy-load every panel.
- Use events instead of polling.
- Use matugen only: no Python and no cava.
- Use compositor blur (`BackgroundEffect`) instead of QML blur.
- Use global shortcuts under appid `somehypr`.
