-- Environment for Hyprland and everything it launches.

-- Wayland-native toolkits
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- GPU vendors from sysfs (0x10de NVIDIA, 0x8086 Intel, 0x1002 AMD), read on
-- every load, so the same config fits any machine.
GPU_VENDORS = {}
for i = 0, 9 do
    local f = io.open("/sys/class/drm/card" .. i .. "/device/vendor", "r")
    if f then
        GPU_VENDORS[f:read("l") or ""] = true
        f:close()
    end
end
local only_nvidia = GPU_VENDORS["0x10de"] and not GPU_VENDORS["0x8086"] and not GPU_VENDORS["0x1002"]

-- NVIDIA as the only GPU (a desktop card, or a laptop in dGPU/MUX mode): VA-API
-- through nvidia-vaapi-driver and the NVIDIA GLX vendor. A hybrid laptop renders
-- on the iGPU, where forcing these breaks GL and video decode, so they stay unset.
-- GBM_BACKEND is left out on purpose: it crashes Firefox-based browsers (Zen) on
-- some driver versions and the driver picks GBM fine without it.
if only_nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end

-- Flatpak apps in launchers
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", HOME .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)

-- Qt theming through KDE platform plugin (Darkly + matugen color scheme).
-- XDG_MENU_PREFIX lets Dolphin find "Open with" entries.
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")
