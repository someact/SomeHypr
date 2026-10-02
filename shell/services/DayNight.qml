pragma Singleton

import QtQuick
import Quickshell
import qs.core

// Day/night schedule (off by default; Config.theme.schedule). At each switch it
// picks a wallpaper from that phase's folder (if the folder has any), sets the
// matugen mode, and turns hyprsunset on at night. Checked once a minute on the
// shared clock, and only while enabled.
Singleton {
    id: root

    readonly property var cfg: Config.theme.schedule
    readonly property bool enabled: cfg.enabled
    property string phase: ""

    function minutes(hhmm) {
        const p = hhmm.split(":");
        return parseInt(p[0]) * 60 + parseInt(p[1] ?? "0");
    }
    function phaseAt(date) {
        const now = date.getHours() * 60 + date.getMinutes();
        const day = minutes(cfg.dayStart), night = minutes(cfg.nightStart);
        const isDay = day < night ? (now >= day && now < night) : (now >= day || now < night);
        return isDay ? "day" : "night";
    }
    function expand(p) {
        return p.replace(/^~/, Paths.home);
    }

    function apply(p, force) {
        phase = p;
        if (!force && Wallpaper.phase === p)
            return;    // already applied (e.g. shell restart): keep the current wallpaper
        Wallpaper.phase = p;
        Config.theme.mode = p === "day" ? cfg.dayMode : cfg.nightMode;
        const folder = expand(p === "day" ? cfg.dayFolder : cfg.nightFolder);
        if (folder !== "")
            Wallpaper.random(folder);    // falls back to the current wallpaper if the folder is empty
        else
            Wallpaper.retheme();
        Wallpaper.save();
        if (cfg.nightLight && NightLight.active !== (p === "night"))
            NightLight.toggle();
    }

    function check() {
        if (!enabled)
            return;
        const p = phaseAt(clock.date);
        if (p !== phase)
            apply(p, false);
    }

    SystemClock {
        id: clock
        enabled: root.enabled
        precision: SystemClock.Minutes
        onDateChanged: root.check()
    }
    onEnabledChanged: check()
    Component.onCompleted: check()
}
