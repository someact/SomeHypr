import QtQuick
import qs.core
import qs.components

// Text on the settings window's surface (Label defaults to island colors)
Label {
    property bool dim: false
    color: dim ? Theme.fgSurfaceVariant : Theme.fgSurface
}
