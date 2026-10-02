pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Screen sharing and microphone use, from Pipewire links.
Singleton {
    readonly property var groups: Pipewire.linkGroups.values
    readonly property bool screenSharing: groups.some(g => g.source?.type === PwNodeType.VideoSource)
    readonly property bool micActive: groups.some(g => g.source?.type === PwNodeType.AudioSource && g.target?.type === PwNodeType.AudioInStream)
    readonly property bool active: screenSharing || micActive
}
