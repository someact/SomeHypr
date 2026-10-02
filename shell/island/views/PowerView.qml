import QtQuick
import qs.core
import qs.components
import qs.services

// Session actions. Destructive ones need a hold (mouse) or a second Enter.
FocusScope {
    id: root

    implicitWidth: actions.length * 84 + (actions.length - 1) * 10
    implicitHeight: 100

    property int selected: 0
    property int armed: -1
    property bool holdDone: false
    readonly property var actions: [
        { icon: "lock", title: "Lock", confirm: false, run: () => Session.lock() },
        { icon: "bedtime", title: "Suspend", confirm: false, run: () => Session.suspend() },
        { icon: "logout", title: "Log out", confirm: true, run: () => Session.logout() },
        { icon: "restart_alt", title: "Restart", confirm: true, run: () => Session.reboot() },
        { icon: "power_settings_new", title: "Shut down", confirm: true, run: () => Session.poweroff() }
    ]

    function trigger(i) {
        const a = actions[i];
        if (a.confirm && armed !== i) {
            armed = i;
            disarm.restart();
            return;
        }
        armed = -1;
        UiState.close();
        a.run();
    }

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            selected = (selected - 1 + actions.length) % actions.length;
            armed = -1;
            return true;
        case Qt.Key_Down:
        case Qt.Key_Tab:
            selected = (selected + 1) % actions.length;
            armed = -1;
            return true;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            trigger(selected);
            return true;
        }
        return UiState.navKey(event);
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    Row {
        anchors.centerIn: parent
        spacing: 10
        Repeater {
            model: root.actions
            PressButton {
                id: btn
                required property var modelData
                required property int index
                width: 84
                height: 96
                radius: Theme.radius.large
                color: Theme.islandRaised
                highlighted: root.selected === index
                activeColor: Theme.error
                active: root.armed === index

                // Hold to confirm: a fill grows while pressed
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: btn.radius
                    color: Qt.rgba(1, 0.27, 0.23, 0.35)
                    height: btn.pressed && btn.modelData.confirm ? parent.height : 0
                    Behavior on height {
                        NumberAnimation {
                            duration: btn.pressed ? 600 : 120
                            onRunningChanged: if (!running && btn.pressed && btn.modelData.confirm) {
                                root.armed = btn.index;
                                root.trigger(btn.index);
                                root.holdDone = true;
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: btn.modelData.icon
                        size: 28
                        fill: btn.active ? 1 : 0
                        color: btn.active ? Theme.fgPrimary : Theme.fgIsland
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.active ? "Again" : btn.modelData.title
                        font.pixelSize: Theme.font.small
                        color: btn.active ? Theme.fgPrimary : Theme.fgIsland
                    }
                }

                // A finished hold already ran the action; a plain click arms it
                onClicked: {
                    if (!root.holdDone)
                        root.trigger(index);
                    root.holdDone = false;
                }
            }
        }
    }
}
