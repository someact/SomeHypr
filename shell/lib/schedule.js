.pragma library

// Time-of-day wallpaper schedule model, shared by services/Schedule.qml (the
// shell, which applies it) and the settings page (which edits it). Pure
// functions over Config.theme.schedule; times are minutes after midnight.

var names = ["sunrise", "noon", "sunset", "night", "midnight"];
var info = {
    sunrise: { title: "Sunrise", icon: "wb_twilight" },
    noon: { title: "Noon", icon: "light_mode" },
    sunset: { title: "Sunset", icon: "routine" },
    night: { title: "Night", icon: "dark_mode" },
    midnight: { title: "Midnight", icon: "bedtime" }
};

function pad(n) {
    return String(n).padStart(2, "0");
}
function minutes(hhmm) {
    var p = String(hhmm || "").split(":");
    return (((parseInt(p[0]) || 0) * 60 + (parseInt(p[1]) || 0)) % 1440 + 1440) % 1440;
}
function hhmm(m) {
    m = ((Math.round(m) % 1440) + 1440) % 1440;
    return pad(Math.floor(m / 60)) + ":" + pad(m % 60);
}
function validTime(t) {
    var m = /^(\d{1,2}):(\d{2})$/.exec(String(t).trim());
    return m !== null && parseInt(m[1]) < 24 && parseInt(m[2]) < 60;
}

// Every slot with every field: saved values over defaults. The defaults of
// sunrise and night come from the day/night keys used before the slots, so an
// old setup keeps working until a slot is edited.
function slots(cfg) {
    var saved = cfg.slots || {};
    var nl = cfg.nightLight;
    var base = {
        sunrise: { on: true, start: cfg.dayStart || "07:00", source: cfg.dayFolder ? "folder" : "keep", folder: cfg.dayFolder || "", mode: cfg.dayMode || "light", nightLight: nl ? "off" : "keep" },
        noon: { on: false, start: "12:00", mode: "light" },
        sunset: { on: false, start: "18:00", mode: "keep" },
        night: { on: true, start: cfg.nightStart || "19:00", source: cfg.nightFolder ? "folder" : "keep", folder: cfg.nightFolder || "", mode: cfg.nightMode || "dark", nightLight: nl ? "on" : "keep" },
        midnight: { on: false, start: "00:00", mode: "dark" }
    };
    var out = {};
    names.forEach(function (n) {
        out[n] = Object.assign({ on: false, start: "00:00", offset: 0, source: "keep", file: "", folder: "", interval: 30, mode: "keep", nightLight: "keep" }, base[n], saved[n] || {});
    });
    return out;
}

// One slot changed, as the full object to write to cfg.slots
function withSlot(cfg, name, patch) {
    var all = slots(cfg);
    all[name] = Object.assign({}, all[name], patch);
    return all;
}

// Start of each slot in minutes. With sun times (sun = { sunrise, sunset } in
// minutes): noon is solar noon, night an hour after sunset, midnight solar
// midnight; each moved by its offset.
function starts(cfg, all, sun) {
    var out = {};
    var fromSun = cfg.sunTimes && sun && sun.sunrise !== undefined;
    var noon = fromSun ? (sun.sunrise + sun.sunset) / 2 : 0;
    var auto = fromSun ? { sunrise: sun.sunrise, noon: noon, sunset: sun.sunset, night: sun.sunset + 60, midnight: noon + 720 } : null;
    names.forEach(function (n) {
        out[n] = auto ? (((Math.round(auto[n] + (all[n].offset || 0)) % 1440) + 1440) % 1440) : minutes(all[n].start);
    });
    return out;
}

// Slots that are on, earliest first: [{ name, start }]
function timeline(all, st) {
    return names.filter(function (n) {
        return all[n].on;
    }).map(function (n) {
        return { name: n, start: st[n] };
    }).sort(function (a, b) {
        return a.start - b.start;
    });
}

// The slot running at `now`: the last one started today, else the last one of
// yesterday (it runs past midnight). "" when none is on.
function current(line, now) {
    if (line.length === 0)
        return "";
    var cur = line[line.length - 1].name;
    line.forEach(function (s) {
        if (s.start <= now)
            cur = s.name;
    });
    return cur;
}
function next(line, now) {
    if (line.length === 0)
        return null;
    for (var i = 0; i < line.length; i++)
        if (line[i].start > now)
            return line[i];
    return line[0];
}
