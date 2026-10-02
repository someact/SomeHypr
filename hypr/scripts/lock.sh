#!/usr/bin/env bash
# Lock the session. Called by hypridle (lock_cmd) and by `loginctl lock-session`.
# Uses the running shell's own lock screen when it answers, hyprlock otherwise
# (shell not running, crashed, or one without a lock screen).
#   lock.sh               lock now
#   lock.sh --after-sleep refocus the shell's lock surface after resume

shell="$(hyprctl repl 'return shell' 2>/dev/null)"
[[ -z "$shell" || "$shell" == "nil" ]] && shell="${qsConfig:-ii}"

if [[ "$1" == "--after-sleep" ]]; then
    case "$shell" in
        ii) hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")' ;;
        somehypr) qs -c somehypr ipc call lock focus 2>/dev/null ;;
    esac
    exit 0
fi

pidof hyprlock >/dev/null && exit 0

case "$shell" in
    ii)
        if pidof qs >/dev/null; then
            hyprctl dispatch 'hl.dsp.global("quickshell:lock")'
            exit 0
        fi
        ;;
    somehypr)
        # `ipc call` fails when no somehypr instance is running
        timeout 3 qs -c somehypr ipc call lock lock 2>/dev/null && exit 0
        ;;
esac

exec hyprlock
