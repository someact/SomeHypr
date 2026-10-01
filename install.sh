#!/usr/bin/env bash
# SomeHypr deploy script. Symlinks repo directories into ~/.config.
#
#   ./install.sh             link everything, reload Hyprland, roll back on config errors
#   ./install.sh --check     only verify the Hyprland config, change nothing
#   ./install.sh --rollback  remove the links and restore the previous directories
#
# The first time a real directory is replaced it is moved to <name>.pre-somehypr,
# which is what --rollback restores.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SUFFIX=".pre-somehypr"

# repo path -> target path
LINKS=(
    "hypr:$CONFIG/hypr"
    "matugen:$CONFIG/matugen"
)
if [[ -f "$REPO/shell/shell.qml" ]]; then
    LINKS+=("shell:$CONFIG/quickshell/somehypr")
fi

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

hypr_running() { [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && hyprctl version >/dev/null 2>&1; }

verify() {
    say "Verifying Hyprland config"
    local out
    out="$(Hyprland --verify-config -c "$REPO/hypr/hyprland.lua" 2>&1 | sed -n '/Config parsing result/,$p' | tail -n +2)"
    echo "$out"
    grep -q '^config ok' <<<"$out"
}

link_one() {
    local src="$REPO/$1" dst="$2"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        say "ok      $dst"
        return
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ -e "$dst$SUFFIX" ]]; then
            local stamp="$dst$SUFFIX.$(date +%Y%m%d-%H%M%S)"
            warn "$dst$SUFFIX exists, moving current $dst to $stamp"
            mv "$dst" "$stamp"
        else
            mv "$dst" "$dst$SUFFIX"
            say "backup  $dst -> $dst$SUFFIX"
        fi
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    say "linked  $dst -> $src"
}

unlink_one() {
    local dst="$2"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$REPO/$1")" ]]; then
        rm "$dst"
        say "removed $dst"
    fi
    if [[ -e "$dst$SUFFIX" && ! -e "$dst" ]]; then
        mv "$dst$SUFFIX" "$dst"
        say "restored $dst"
    fi
}

# State that ii keeps inside ~/.config/hypr and that should survive the swap
carry_state() {
    local old="$CONFIG/hypr"
    [[ -L "$old" ]] && return
    if [[ -d "$old/custom/scripts" ]]; then
        mkdir -p "$REPO/hypr/custom"
        cp -rn "$old/custom/scripts" "$REPO/hypr/custom/" 2>/dev/null || true
    fi
    [[ -f "$old/hyprland/colors.lua" && ! -f "$REPO/hypr/generated/colors.lua" ]] &&
        cp "$old/hyprland/colors.lua" "$REPO/hypr/generated/colors.lua"
    [[ -f "$old/hyprlock/colors.conf" && ! -f "$REPO/hypr/generated/hyprlock-colors.conf" ]] &&
        cp "$old/hyprlock/colors.conf" "$REPO/hypr/generated/hyprlock-colors.conf"
    return 0
}

reload_session() {
    hypr_running || return 0
    say "Reloading Hyprland"
    hyprctl reload >/dev/null
    sleep 1
    local errors
    errors="$(hyprctl configerrors)"
    if [[ -n "${errors//[[:space:]]/}" ]]; then
        warn "Hyprland reported config errors:"
        echo "$errors" >&2
        return 1
    fi
    # hypridle reads its config only at start
    if pidof hypridle >/dev/null; then
        pkill -x hypridle || true
        setsid -f hypridle >/dev/null 2>&1
    fi
}

rollback() {
    for entry in "${LINKS[@]}"; do unlink_one "${entry%%:*}" "${entry#*:}"; done
    if hypr_running; then
        hyprctl reload >/dev/null
        pkill -x hypridle || true
        setsid -f hypridle >/dev/null 2>&1
    fi
    say "Rolled back"
}

case "${1:-}" in
    --check)
        verify
        ;;
    --rollback)
        rollback
        ;;
    "")
        verify || { warn "Config does not verify, nothing changed"; exit 1; }
        carry_state
        for entry in "${LINKS[@]}"; do link_one "${entry%%:*}" "${entry#*:}"; done
        if ! reload_session; then
            warn "Rolling back"
            rollback
            exit 1
        fi
        say "Done"
        ;;
    *)
        sed -n '2,9p' "$0"
        exit 2
        ;;
esac
