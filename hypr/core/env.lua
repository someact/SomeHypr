-- Environment for Hyprland and everything it launches.

-- Wayland-native toolkits
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- NVIDIA (RTX 3060, nvidia-open). VA-API through nvidia-vaapi-driver and the
-- NVIDIA GLX vendor. GBM_BACKEND is left out on purpose: it crashes Firefox-based
-- browsers (Zen) on some driver versions and the driver picks GBM fine without it.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Flatpak apps in launchers
local xdg_data_dirs_old = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", HOME .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdg_data_dirs_old)

-- Qt theming through KDE platform plugin (Darkly + matugen color scheme).
-- XDG_MENU_PREFIX lets Dolphin find "Open with" entries.
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Shell selection, visible to scripts as $qsConfig
hl.env("qsConfig", shell)

-- ii compatibility: its wallpaper/color scripts run inside this venv.
-- Remove together with ii in Phase 8.
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", HOME .. "/.local/state/quickshell/.venv")
