import QtQuick
import qs.core
import qs.components
import qs.services
import qs.settings
import qs.settings.ui

// Laptops only (listed while Battery.available). Reads the battery from UPower
// directly: it is system state, not shell state, so no IPC is needed.
Page {
    title: "Power"
    subtitle: "Battery status and charging."

    Section {
        title: "Battery"
        SettingRow {
            icon: Battery.icon
            title: Battery.percent + "%"
            subtitle: [Battery.timeText, Battery.health >= 0 ? "health " + Battery.health + "%" : ""].filter(s => s !== "").join(" · ")
        }
    }

    Section {
        title: "Charging"
        note: Battery.limitSupported ? (Battery.limitStart > 0 || Battery.limitEnd > 0 ? "Charging starts below " + Battery.limitStart + "% and stops at " + Battery.limitEnd + "%. Plugged in, the laptop runs from the charger instead of cycling the battery." : "Conservation mode: the battery stops charging around 80% (the firmware picks the level) and the laptop runs straight from the charger. Good for a laptop that stays plugged in; turn it off before a trip to charge to 100%.") : "This battery has no charge limit that UPower can control."
        SettingRow {
            icon: "battery_saver"
            title: "Battery bypass"
            subtitle: "Stop charging early and run from the charger. Also a quick tile in Control."
            enabled: Battery.limitSupported
            Switch {
                checked: Battery.limitEnabled
                onToggled: on => Battery.setLimit(on)
            }
        }
    }
}
