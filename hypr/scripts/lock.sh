#!/usr/bin/env bash
# Lock the session. Called by hypridle (lock_cmd) and by `loginctl lock-session`.
# Uses the running shell's own lock screen when it has one, hyprlock otherwise.
#   lock.sh               lock now
#   lock.sh --after-sleep refocus the shell's lock surface after resume

shell="$(hyprctl repl 'return shell' 2>/dev/null)"
[[ -z "$shell" || "$shell" == "nil" ]] && shell="${qsConfig:-ii}"

if [[ "$1" == "--after-sleep" ]]; then
    [[ "$shell" == "ii" ]] && hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")'
    exit 0
fi

if [[ "$shell" == "ii" ]] && pidof qs >/dev/null; then
    hyprctl dispatch 'hl.dsp.global("quickshell:lock")'
    exit 0
fi

pidof hyprlock >/dev/null || exec hyprlock
