# SomeHypr

Personal Hyprland desktop for one machine: CachyOS, Hyprland 0.56 (Lua config), RTX 3060, one 1920x1080@100 monitor (DP-1), US/TH keyboard, UGTablet pen.
Goals are in `idea.md`. The full plan, with phases and targets, is in `docs/plan.md`.

## Layout
- `hypr/` is linked to `~/.config/hypr`. `hyprland.lua` loads files in a fixed order, and each setting lives in exactly one file:
  - `user.lua` holds user choices: apps, `glass`, `gameModeAuto`. The settings app overrides them through `~/.config/somehypr/hypr.json` (`SETTINGS`, loaded by `lib/util.lua` with `lib/json.lua`); `core/settings.lua` loads last and applies its `hyprland` table (a partial `hl.config`). The file only holds changed values.
  - `core/` covers env (NVIDIA), input and tablet, look, motion, misc, and execs.
  - `rules/` holds window rules (windows, media, art, gaming) and layer rules.
  - `binds/keybinds.lua` holds every bind. Shell binds go through `shell_bind()` / `SHELL_ACTIONS` in `binds/shell.lua`: a `somehypr:` global shortcut plus an optional CLI fallback that runs only while the shell is not answering.
  - `binds/user.lua` applies `~/.config/somehypr/keybinds.json` (settings app): it wraps `hl.bind` while keybinds.lua runs (remap/disable by normalized combo), then `UserBinds.finish()` adds custom binds and the `somehypr-record` submap. User changes never go into keybinds.lua.
  - `modes/gamemode.lua` turns blur, shadows and animations off while a game is the focused fullscreen window. Control it with `hyprctl eval 'GameMode.toggle()'` and `'GameMode.auto()'`.
  - `generated/` is machine-written (matugen) and gitignored. `monitors.lua` is written by the display settings page.
- `matugen/` is linked to `~/.config/matugen` and is the only color engine. `config.toml` lists every output (shell, Hyprland, terminals, GTK, KDE, fuzzel, Zen, Vesktop); `hooks/` reload apps. Run it without a terminal only with `--source-color-index 0`.
- Wallpaper state is `~/.local/state/somehypr/wallpaper.json`; set it through the shell (`qs -c somehypr ipc call wallpaper set <path>`) so videos start mpvpaper and get a matugen frame. Images are shown from a screen-sized copy (`~/.cache/somehypr/wall-<WxH>-<md5>.jpg`, ImageMagick), because Qt keeps a large original's full decode in memory.
- `shell/` is linked to `~/.config/quickshell/somehypr` and runs with `qs -c somehypr`:
  - `core/` singletons (Config, Theme, Motion, Paths, UiState, GameMode), `components/`, `services/` (one singleton per system source).
  - `island/Island.qml` is the notch window; `island/views/*View.qml` are loaded only while open; `island/ambient/` holds the collapsed states.
  - `commands/` holds one file per `/command`, registered in `commands/Commands.qml`.
  - `Shortcuts.qml` (global shortcuts) and `Ipc.qml` (IPC targets) sit at the root; `corners/` holds the pills and `wallpaper/` the background layer.
  - `settings.qml` + `settings/` is the settings app, a separate process (`qs -c somehypr ipc call settings open` or `settings page <id>`; a second call focuses the running one). `settings/` holds its stores (HyprSettings, KeybindStore, ShellIpc), `ui/` and one file per page in `pages/`. It changes shell state over IPC, never by running a second copy of a service.
  - `capture/RegionSelector.qml` is the region picker over a grim-frozen frame; `services/Capture.qml` runs the tools and `services/Recorder.qml` owns wf-recorder (the island shows the timer).
  - `overlay/` is the Super+G game overlay (one card file per widget). It has no blur on purpose: layer blur uses `xray` and would hide the game.
  - `services/Streamer.qml` is streamer mode; peeks then go to `island/PrivatePeek.qml` on the `somehypr:private` layer (`no_screen_share`). `services/GameClients.qml` feeds gamemoded PIDs to `GameMode.set_clients()`.
  - `lock/` is the lock screen (`WlSessionLock`, surfaces only while locked); state and PAM live in `services/Lock.qml`. `hypr/scripts/lock.sh` calls `ipc call lock lock` and runs hyprlock when the shell does not answer. There is no unlock IPC; test with `ipc call lock preview` (no PAM, Esc closes).
  - `widgets/` holds the desktop widgets (bottom layer, one window per screen, hidden in game mode); `services/Widgets.qml` lists them, `config.json` `widgets` stores which are on and where. Edit mode: `ipc call widgets edit`.
  - `osk/` is the Super+K keyboard; `services/VirtualKeys.qml` types through ydotoold (`YDOTOOL_SOCKET` is passed per call, the shell's env lacks it).
  - `dock/` is the bottom dock (contents from `services/Taskbar.qml`, settings under `dock` in config.json). `overview/` is Super+Tab, created only while open.
  - Blur gotcha: an empty `BackgroundEffect.blurRegion` blurs the whole surface, so set it to `null` whenever the shape is off-surface.
  - QML gotcha: a property named `onX` is parsed as a signal handler, so theme colors use `fgX` (e.g. `Theme.fgIsland`).
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
- After a phase is done and verified, commit and push to GitHub (`git push origin main`, remote `someact/SomeHypr`, private). Mark the phase ✅ in the plan in the same push.

## Rules for the shell (Phase 2 onward)
- Lazy-load every panel.
- Use events instead of polling.
- Use matugen only: no Python and no cava.
- Use compositor blur (`BackgroundEffect`) instead of QML blur.
- Use global shortcuts under appid `somehypr`.
