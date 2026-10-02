import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.components
import qs.services
import "ambient"
import "views"

// The island: one top-layer window per monitor. Collapsed it shows the most
// important ambient state; expanded it hosts one view at a time. The notch
// shape springs to the size of whatever it holds, and the content follows a
// beat later, so shape and content move as one reaction.
//
// The window is larger than the notch; `mask` passes clicks outside the notch
// through, and the compositor blurs only the notch (BackgroundEffect).
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    readonly property bool isFocusedScreen: (Hyprland.focusedMonitor?.name ?? modelData.name) === modelData.name
    readonly property bool open: UiState.expanded && isFocusedScreen

    // Ambient priority: polkit → notification → OSD → privacy → media → game dot → clock
    readonly property string ambient: {
        if (Polkit.active)
            return "polkit";
        if (Notifs.peeked)
            return "notif";
        if (Osd.visible)
            return "osd";
        if (Privacy.active)
            return "privacy";
        if (GameMode.active)
            return "dot";
        if (Media.active && Config.island.showMedia)
            return "media";
        return "clock";
    }

    readonly property real ear: 12
    readonly property real pad: 18
    readonly property real minCollapsedWidth: 160
    readonly property bool showTabs: UiState.mainViews.includes(UiState.view)

    readonly property real targetWidth: {
        if (open && viewLoader.item)
            return viewLoader.item.implicitWidth + pad * 2;
        const a = ambientLoader.item;
        if (ambient === "dot")
            return a?.implicitWidth ?? 24;
        return Math.max(minCollapsedWidth, (a?.implicitWidth ?? 60) + 32);
    }
    readonly property real targetHeight: {
        if (open && viewLoader.item)
            return (showTabs ? tabs.height + 10 : 0) + viewLoader.item.implicitHeight + pad * 2 - 4;
        const a = ambientLoader.item;
        if (ambient === "dot")
            return a?.implicitHeight ?? 6;
        return Math.max(Theme.barHeight, a?.implicitHeight ?? Theme.barHeight);
    }

    WlrLayershell.namespace: "somehypr:island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.top: true
    exclusiveZone: UiState.hidden ? 0 : Theme.barHeight
    implicitWidth: 1000
    implicitHeight: 720
    color: "transparent"

    mask: Region {
        item: notch
    }

    // Compositor frost behind the notch body only
    Region {
        id: blurArea
        item: body
        bottomLeftRadius: notch.r
        bottomRightRadius: notch.r
    }
    // Not while hidden off the surface: an empty region blurs the whole window
    BackgroundEffect.blurRegion: Theme.glass && !GameMode.active && body.y + body.height > 1 ? blurArea : null

    Binding {
        target: UiState
        property: "ambient"
        value: win.ambient
        when: win.isFocusedScreen
    }

    // Click outside closes. The grab starts a moment after opening: activated
    // in the same frame as the keyboard-focus change, Hyprland clears it at once.
    HyprlandFocusGrab {
        id: grab
        windows: [win]
        onCleared: if (win.open) UiState.close()
    }
    Timer {
        id: grabDelay
        interval: 50
        onTriggered: grab.active = win.open
    }
    onOpenChanged: {
        if (open) {
            grabDelay.restart();
        } else {
            grab.active = false;
            unload.restart();
        }
    }

    IdleInhibitor {
        window: win
        enabled: UiState.caffeine
    }

    // Keep the view loaded until the collapse has played out
    Timer {
        id: unload
        interval: 450
    }

    RectangularShadow {
        anchors.fill: body
        radius: notch.r
        blur: 30
        spread: 0
        offset: Qt.vector2d(0, 6)
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: win.open ? 1 : 0
        visible: opacity > 0 && !GameMode.active
        Behavior on opacity {
            NumberAnimation { duration: Motion.normal }
        }
    }

    NotchShape {
        id: notch
        x: body.x - ear
        y: body.y
        bodyWidth: body.width
        bodyHeight: body.height
        ear: Math.min(win.ear, body.height)
        radius: win.open ? Theme.radius.island : Math.min(body.height / 2, Theme.radius.island)
        color: Theme.island
    }

    Item {
        id: body

        width: win.targetWidth
        height: win.targetHeight
        x: Math.round((win.width - width) / 2)
        y: UiState.hidden ? -height - 4 : 0
        clip: true

        Behavior on width {
            Spring { preset: "smooth" }
        }
        Behavior on height {
            Spring { preset: "smooth" }
        }
        Behavior on y {
            Spring { preset: "snappy" }
        }

        // Click the collapsed island to open what it is showing
        MouseArea {
            anchors.fill: parent
            enabled: !win.open
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: event => {
                if (event.button === Qt.RightButton) {
                    UiState.open("control");
                    return;
                }
                switch (win.ambient) {
                case "polkit":
                    UiState.open("polkit");
                    break;
                case "notif":
                    Notifs.peeked = null;
                    UiState.open("notifications");
                    break;
                case "media":
                    UiState.open("media");
                    break;
                case "osd":
                case "privacy":
                    UiState.open("control");
                    break;
                default:
                    UiState.open("search");
                }
            }
            onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
        }

        // Collapsed content
        Loader {
            id: ambientLoader
            anchors.centerIn: parent
            active: !win.open || unload.running
            opacity: win.open ? 0 : 1
            visible: opacity > 0
            sourceComponent: {
                switch (win.ambient) {
                case "polkit":
                    return polkitAmbient;
                case "notif":
                    return notifAmbient;
                case "osd":
                    return osdAmbient;
                case "privacy":
                    return privacyAmbient;
                case "dot":
                    return dotAmbient;
                case "media":
                    return mediaAmbient;
                }
                return clockAmbient;
            }
            onLoaded: reveal.restart()
            Behavior on opacity {
                NumberAnimation { duration: Motion.fast }
            }
            ContentReveal {
                id: reveal
                target: ambientLoader.item
            }
        }

        // Expanded content
        FocusScope {
            id: keys
            anchors.fill: parent
            anchors.margins: win.pad
            anchors.topMargin: win.pad - 6
            focus: win.open
            opacity: win.open ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: win.open ? Motion.normal : Motion.fast }
            }

            Keys.onPressed: event => {
                const v = viewLoader.item;
                if (v?.handleKey) {
                    if (v.handleKey(event))
                        event.accepted = true;
                    return;
                }
                if (UiState.navKey(event))
                    event.accepted = true;
            }

            ViewTabs {
                id: tabs
                visible: win.showTabs
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Loader {
                id: viewLoader
                anchors.top: win.showTabs ? tabs.bottom : parent.top
                anchors.topMargin: win.showTabs ? 10 : 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: item ? item.implicitWidth : 0
                height: item ? item.implicitHeight : 0
                focus: true
                active: win.open || unload.running
                sourceComponent: {
                    switch (UiState.view) {
                    case "control":
                        return controlView;
                    case "media":
                        return mediaView;
                    case "notifications":
                        return notificationsView;
                    case "system":
                        return systemView;
                    case "power":
                        return powerView;
                    case "clipboard":
                        return clipboardView;
                    case "emoji":
                        return emojiView;
                    case "keys":
                        return keysView;
                    case "polkit":
                        return polkitView;
                    case "wallpaper":
                        return wallpaperView;
                    }
                    return searchView;
                }
                onLoaded: viewReveal.restart()
                ContentReveal {
                    id: viewReveal
                    target: viewLoader.item
                }
            }
        }
    }

    // Content fades and scales in slightly after the shape starts moving
    component ContentReveal: SequentialAnimation {
        id: anim
        property Item target
        ScriptAction {
            script: if (anim.target) {
                anim.target.opacity = 0;
                anim.target.scale = 0.96;
            }
        }
        PauseAnimation {
            duration: Motion.reduced ? 0 : 60
        }
        ParallelAnimation {
            NumberAnimation {
                target: anim.target
                property: "opacity"
                to: 1
                duration: Motion.normal
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: anim.target
                property: "scale"
                to: 1
                duration: Motion.normal
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
    }

    component ViewTabs: Row {
        spacing: 4
        readonly property var icons: ({ search: "search", control: "tune", media: "music_note", notifications: "notifications", system: "monitoring", power: "power_settings_new" })
        Repeater {
            model: UiState.mainViews
            IconButton {
                required property string modelData
                width: 30
                height: 26
                iconSize: 17
                icon: parent.icons[modelData]
                active: UiState.view === modelData
                activeColor: Theme.islandRaisedHover
                iconColor: active ? Theme.fgIsland : Theme.fgIslandDim
                onClicked: UiState.view = modelData
            }
        }
    }

    Component {
        id: clockAmbient
        AmbientClock {}
    }
    Component {
        id: mediaAmbient
        AmbientMedia {}
    }
    Component {
        id: osdAmbient
        AmbientOsd {}
    }
    Component {
        id: notifAmbient
        AmbientNotif {}
    }
    Component {
        id: privacyAmbient
        AmbientPrivacy {}
    }
    Component {
        id: dotAmbient
        AmbientDot {}
    }
    Component {
        id: polkitAmbient
        Item {
            implicitWidth: polkitRow.implicitWidth
            implicitHeight: Theme.barHeight
            Row {
                id: polkitRow
                anchors.centerIn: parent
                spacing: 8
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "admin_panel_settings"
                    size: 18
                    fill: 1
                    color: Theme.primary
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Authentication needed"
                }
            }
        }
    }

    Component {
        id: searchView
        SearchView {}
    }
    Component {
        id: controlView
        ControlView {}
    }
    Component {
        id: mediaView
        MediaView {}
    }
    Component {
        id: notificationsView
        NotificationsView {}
    }
    Component {
        id: systemView
        SystemView {}
    }
    Component {
        id: powerView
        PowerView {}
    }
    Component {
        id: clipboardView
        ClipboardView {}
    }
    Component {
        id: emojiView
        EmojiView {}
    }
    Component {
        id: keysView
        KeysView {}
    }
    Component {
        id: polkitView
        PolkitView {}
    }
    Component {
        id: wallpaperView
        WallpaperView {}
    }
}
