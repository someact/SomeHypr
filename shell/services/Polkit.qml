pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs.core

// Native polkit agent. A request opens the island's polkit view.
Singleton {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: UiState.open("polkit")
    }
}
