pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core
import "../lib/schedule.js" as Slots

// Time-of-day schedule (off by default; Config.theme.schedule, model in
// lib/schedule.js). At each slot's start it applies the slot: wallpaper (keep,
// one file, or a random one from a folder), light/dark colors and night light.
// A dynamic slot also re-picks from its folder every `interval` minutes while it
// lasts (not in game mode). Checked once a minute on the shared clock, only
// while enabled. Sun times come from Open-Meteo once a day, only while used.
Singleton {
    id: root

    readonly property var cfg: Config.theme.schedule
    readonly property bool enabled: cfg.enabled
    readonly property var slots: Slots.slots(cfg)
    readonly property var starts: Slots.starts(cfg, slots, sun)
    readonly property var line: Slots.timeline(slots, starts)

    property string phase: ""          // the slot applied last
    property bool previewing: false    // a previewed slot holds until the next start
    property int testNow: -1           // minutes; set over IPC to test a time of day

    // { date, place, sunrise, sunset } (minutes), cached in the state dir
    property var sun: null
    readonly property bool wantSun: enabled && cfg.sunTimes
    readonly property string place: Config.widgets.weatherCity

    readonly property var active: phase !== "" ? slots[phase] : null
    readonly property bool dynamic: enabled && !previewing && active !== null && active.source === "dynamic" && active.folder !== ""

    function today() {
        const d = clock.date;
        return d.getFullYear() + "-" + Slots.pad(d.getMonth() + 1) + "-" + Slots.pad(d.getDate());
    }
    function now() {
        return testNow >= 0 ? testNow : clock.date.getHours() * 60 + clock.date.getMinutes();
    }
    function minutesOf(t) {
        return Slots.minutes(t);
    }
    function expand(p) {
        return p.replace(/^~/, Paths.home);
    }

    function apply(name, preview) {
        const s = slots[name];
        if (!s)
            return;
        if (!preview) {
            phase = name;
            Wallpaper.phase = name;
        }
        previewing = !!preview;
        const modeChanged = s.mode !== "keep" && s.mode !== Config.theme.mode;
        if (modeChanged)
            Config.theme.mode = s.mode;
        if (s.source === "file" && s.file !== "" && s.file !== Wallpaper.path)
            Wallpaper.set(expand(s.file));
        else if ((s.source === "folder" || s.source === "dynamic") && s.folder !== "")
            Wallpaper.random(expand(s.folder));    // keeps the current one if the folder is empty
        else if (modeChanged)
            Wallpaper.retheme();
        Wallpaper.save();
        if (s.nightLight !== "keep" && NightLight.active !== (s.nightLight === "on"))
            NightLight.toggle();
        // `rotate` follows `dynamic` by binding; restart() here would break it
    }

    function check() {
        if (!enabled || !Wallpaper.loaded)
            return;
        if (phase === "")    // after a restart: the slot saved with the wallpaper (day/night from before the slots)
            phase = ({ day: "sunrise" })[Wallpaper.phase] ?? Wallpaper.phase;
        const cur = Slots.current(line, now());
        if (cur !== "" && cur !== phase)
            apply(cur, false);
    }
    function preview(name) {
        apply(name, true);
    }

    // For `ipc call schedule state`
    function state() {
        const n = Slots.next(line, now());
        return JSON.stringify({
            enabled: enabled,
            phase: phase,
            previewing: previewing,
            dynamic: rotate.running,
            now: Slots.hhmm(now()),
            next: n ? n.name + " " + Slots.hhmm(n.start) : "",
            sun: sun ? { sunrise: Slots.hhmm(sun.sunrise), sunset: Slots.hhmm(sun.sunset), place: sun.place, date: sun.date } : null,
            slots: line.map(s => s.name + " " + Slots.hhmm(s.start) + " " + slots[s.name].source)
        });
    }

    SystemClock {
        id: clock
        enabled: root.enabled
        precision: SystemClock.Minutes
        onDateChanged: {
            root.check();
            root.fetchSun();
        }
    }
    onEnabledChanged: check()
    onLineChanged: check()
    Component.onCompleted: check()
    Connections {
        target: Wallpaper
        function onLoadedChanged() {
            root.check();
        }
    }

    // Dynamic slot: a new random wallpaper from its folder every `interval` min
    Timer {
        id: rotate
        interval: Math.max(1, root.active?.interval ?? 30) * 60000
        repeat: true
        running: root.dynamic && !GameMode.active
        onTriggered: Wallpaper.random(root.expand(root.active.folder))
    }

    // Sun times: one curl chain a day, only while the option is on
    onWantSunChanged: fetchSun()
    onPlaceChanged: fetchSun()
    function fetchSun() {
        if (!wantSun || !sunFile.loaded || sunProc.running)
            return;
        if (sun && sun.date === today() && sun.place === place)
            return;
        sunProc.command = ["sh", "-c", Weather.locate + '
f=$(curl -sfG -m 10 -A "$ua" -d latitude=$lat -d longitude=$lon -d timezone=auto -d forecast_days=1 -d daily=sunrise,sunset https://api.open-meteo.com/v1/forecast) || exit 1
printf %s "$f" | jq -r ".daily.sunrise[0], .daily.sunset[0]"', "_", place.trim()];
        sunProc.running = true;
    }
    Process {
        id: sunProc
        stdout: StdioCollector {
            id: sunOut
        }
        onExited: code => {
            // "2026-10-03T06:02\n2026-10-03T17:58"
            const t = sunOut.text.trim().split("\n").map(l => l.split("T")[1] ?? "");
            if (code !== 0 || t.length < 2 || !Slots.validTime(t[0]) || !Slots.validTime(t[1])) {
                console.warn("Schedule: no sun times (" + (code === 2 ? "place not found" : "no connection") + "), using the slot times");
                return;
            }
            root.sun = { date: root.today(), place: root.place, sunrise: Slots.minutes(t[0]), sunset: Slots.minutes(t[1]) };
            sunFile.setText(JSON.stringify(root.sun));
        }
    }
    FileView {
        id: sunFile
        property bool loaded: false
        path: Paths.stateDir + "/sun.json"
        printErrors: false
        onLoaded: {
            try {
                root.sun = JSON.parse(text());
            } catch (e) {}
            loaded = true;
            root.fetchSun();
        }
        onLoadFailed: {
            loaded = true;
            root.fetchSun();
        }
    }
}
