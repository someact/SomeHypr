# SomeHypr

Personal Hyprland desktop for one machine: CachyOS, Hyprland 0.56 (Lua config), RTX 3060, one 1920x1080@100 monitor (DP-1), US/TH keyboard, UGTablet pen.
Goals are in `idea.md`. The full plan, with phases and targets, is in `docs/plan.md`.

## Layout
- `hypr/` is linked to `~/.config/hypr`. `hyprland.lua` loads files in a fixed order, and each setting lives in exactly one file:
  - `user.lua` holds user choices: `shell`, apps, `glass`, `gameModeAuto`.
  - `core/` covers env (NVIDIA), input and tablet, look, motion, misc, and execs.
  - `rules/` holds window rules (windows, media, art, gaming) and layer rules.
  - `binds/keybinds.lua` holds every bind. Shell binds go through `shell_bind()` / `SHELL_ACTIONS` in `binds/shell.lua`, so switching `shell` retargets them.
  - `modes/gamemode.lua` turns blur, shadows and animations off while a game is the focused fullscreen window. Control it with `hyprctl eval 'GameMode.toggle()'` and `'GameMode.auto()'`.
  - `generated/` is machine-written (matugen) and gitignored. `monitors.lua` is written by the display settings page.
  - `hyprland/scripts` is a symlink so that ii's hardcoded paths keep working. Remove it with ii in Phase 8.
- `matugen/` is linked to `~/.config/matugen` and is the only color engine.
- `shell/` (Phase 2) will be linked to `~/.config/quickshell/somehypr` and run with `qs -c somehypr`.
- `install.sh` links everything and reloads, rolling back automatically if there are config errors. `--check` only verifies; `--rollback` restores `~/.config/*.pre-somehypr`.

## Hyprland Lua API
- The authoritative stub is `/usr/share/hypr/stubs/hl.meta.lua`: events, rule fields, config keys and dispatchers. Example config: `/usr/share/hypr/hyprland.lua`.
- Window and layer rules take effects as flat fields, e.g. `hl.window_rule({ match = {...}, no_blur = true })`. Unknown fields are config errors.
- Springs: `hl.curve(name, { type = "spring", mass, stiffness, dampening })`, used as `spring = name` in `hl.animation`.
- Runtime: `hyprctl eval '<lua>'` runs code, and `hyprctl repl 'return <expr>'` reads Lua globals (e.g. `shell`, `GameMode.active`).

## Verify every change
```sh
./install.sh --check                 # Hyprland --verify-config on the repo config
hyprctl reload && hyprctl configerrors   # live; must print nothing
hyprctl binds -j | jq length         # 201 after Phase 1 (ii had 191, +10 Thai keycode binds)
```
Never edit `~/.config/hypr.pre-somehypr` or `~/.config/quickshell/ii`. They are the rollback.

## Rules for the shell (Phase 2 onward)
- Lazy-load every panel.
- Use events instead of polling.
- Use matugen only: no Python and no cava.
- Use compositor blur (`BackgroundEffect`) instead of QML blur.
- Use global shortcuts under appid `somehypr`.
