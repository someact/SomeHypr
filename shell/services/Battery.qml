pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// The laptop battery (UPower's display device) and its charge limit.
// `available` is false on a desktop, so everything that shows the battery hides.
//
// Charge limit ("battery bypass"): UPower's EnableChargeThreshold. The kernel
// driver decides what that means: a start/stop threshold on most laptops, or
// conservation mode (charge_types Long_Life) on Lenovo IdeaPad/Legion, which
// holds the battery near 80% and runs the laptop from the charger.
// Polkit lets the active session change it without a password.
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device.ready && device.isLaptopBattery && device.isPresent
    readonly property real level: device.percentage            // 0..1
    readonly property int percent: Math.round(level * 100)
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool full: device.state === UPowerDeviceState.FullyCharged
    readonly property bool onBattery: UPower.onBattery
    readonly property bool low: available && onBattery && percent <= 15

    readonly property string icon: {
        if (charging || full && !onBattery)
            return percent >= 95 ? "battery_charging_full" : percent >= 85 ? "battery_charging_90" : percent >= 70 ? "battery_charging_80" : percent >= 55 ? "battery_charging_60" : percent >= 40 ? "battery_charging_50" : percent >= 25 ? "battery_charging_30" : "battery_charging_20";
        if (percent >= 95)
            return "battery_full";
        if (low)
            return "battery_alert";
        return "battery_" + Math.min(6, Math.floor(percent / 14)) + "_bar";
    }

    // "1 h 20 m left", "40 m to full", "Plugged in"
    function duration(s) {
        const m = Math.round(s / 60);
        return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " m" : m + " m";
    }
    readonly property string timeText: {
        if (charging && device.timeToFull > 0)
            return duration(device.timeToFull) + " to full";
        if (onBattery && device.timeToEmpty > 0)
            return duration(device.timeToEmpty) + " left";
        if (!onBattery)
            return limitEnabled ? "Plugged in · limit on" : full ? "Full" : "Plugged in";
        return "";
    }
    readonly property string summary: percent + "%" + (timeText !== "" ? " · " + timeText : "")
    readonly property int health: device.healthSupported ? Math.round(device.healthPercentage) : -1

    // Charge limit, read from UPower once the battery is known and after each change
    property bool limitSupported: false
    property bool limitEnabled: false
    property int limitStart: 0          // 0/0: the firmware picks the level (conservation mode)
    property int limitEnd: 0
    // The display device is UPower's combined view with no path of its own;
    // the limit is set on the first real laptop battery
    readonly property UPowerDevice battery: UPower.devices.values.find(d => d.isLaptopBattery && d.nativePath !== "") ?? null
    readonly property string objectPath: battery ? "/org/freedesktop/UPower/devices/battery_" + battery.nativePath : ""

    function setLimit(on) {
        if (!limitSupported || objectPath === "")
            return;
        limitEnabled = on;              // shown at once; the read below corrects it on failure
        setter.command = ["busctl", "call", "org.freedesktop.UPower", objectPath, "org.freedesktop.UPower.Device", "EnableChargeThreshold", "b", String(on)];
        setter.running = true;
    }
    function toggleLimit() {
        setLimit(!limitEnabled);
    }
    function readLimit() {
        if (objectPath === "" || reader.running)
            return;
        reader.command = ["busctl", "get-property", "org.freedesktop.UPower", objectPath, "org.freedesktop.UPower.Device", "ChargeThresholdSupported", "ChargeThresholdEnabled", "ChargeStartThreshold", "ChargeEndThreshold"];
        reader.running = true;
    }
    onObjectPathChanged: readLimit()
    Component.onCompleted: readLimit()     // the device may already be known
    // Another tool may change the limit; plugging in is a cheap moment to re-check
    onOnBatteryChanged: readLimit()

    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                // "b true\nb false\nu 0\nu 0"
                const v = text.trim().split("\n").map(l => l.trim().split(/\s+/)[1]);
                if (v.length < 4)
                    return;
                root.limitSupported = v[0] === "true";
                root.limitEnabled = v[1] === "true";
                root.limitStart = parseInt(v[2]) || 0;
                root.limitEnd = parseInt(v[3]) || 0;
            }
        }
    }
    Process {
        id: setter
        stderr: StdioCollector {
            id: setterErr
        }
        onExited: code => {
            if (code !== 0)
                console.warn("Battery: EnableChargeThreshold failed: " + setterErr.text.trim());
            root.readLimit();
        }
    }
}
