pragma Singleton

import QtQuick
import Quickshell

// Key presses for the on-screen keyboard, through ydotoold (uinput), so they
// reach whatever window has focus and follow the active layout (US/TH).
// Each tap is one short ydotool call that presses and releases the key with
// its modifiers, so a key can never be left stuck down.
//
// Modifiers are sticky: a tap latches one for the next key, a second tap within
// 400 ms locks it, a tap on a locked one releases it.
Singleton {
    id: root

    readonly property string socket: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/.ydotool_socket"
    property var mods: ({})         // keycode -> 1 latched, 2 locked
    property var lastModTap: ({})   // keycode -> ms

    readonly property bool shift: (mods[42] ?? 0) > 0

    function state(code) {
        return mods[code] ?? 0;
    }

    function send(events) {
        Quickshell.execDetached(["env", "YDOTOOL_SOCKET=" + socket, "ydotool", "key", "--key-delay", "0", ...events]);
    }

    function tap(code) {
        const held = Object.keys(mods).map(Number);
        send([...held.map(m => m + ":1"), code + ":1", code + ":0", ...held.reverse().map(m => m + ":0")]);
        // Latched modifiers apply to one key; locked ones stay
        const keep = {};
        for (const k in mods)
            if (mods[k] === 2)
                keep[k] = 2;
        mods = keep;
    }

    function toggleMod(code) {
        const now = Date.now();
        const s = state(code);
        const next = Object.assign({}, mods);
        if (s === 0)
            next[code] = 1;
        else if (s === 1 && now - (lastModTap[code] ?? 0) < 400)
            next[code] = 2;
        else
            delete next[code];
        lastModTap = Object.assign({}, lastModTap, { [code]: now });
        mods = next;
    }

    function reset() {
        mods = {};
    }
}
