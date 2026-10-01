-- Autostart. Runs once when Hyprland starts, not on config reload.

hl.on("hyprland.start", function()
    -- Desktop shell (bar/island, wallpaper, notifications, polkit agent)
    hl.exec_cmd("qs -c " .. shell)

    -- ii writes this restore script when a video wallpaper is chosen in its picker
    if shell == "ii" then
        hl.exec_cmd("[ -f ~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh ] && bash ~/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")
    end

    -- Session plumbing
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Clipboard history. ii needs an IPC nudge to refresh its list; the new
    -- shell watches the clipboard itself.
    if shell == "ii" then
        hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'")
        hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'")
    else
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end

    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
