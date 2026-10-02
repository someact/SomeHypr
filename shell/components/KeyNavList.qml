import QtQuick
import qs.core

// ListView driven from outside (the island owns keyboard focus). Call
// up()/down()/activate(); delegates read ListView.isCurrentItem and handle
// `activated(index)`.
ListView {
    id: root

    signal activated(int index)

    function up() {
        if (count > 0)
            currentIndex = (currentIndex - 1 + count) % count;
    }
    function down() {
        if (count > 0)
            currentIndex = (currentIndex + 1) % count;
    }
    function activate() {
        if (currentIndex >= 0 && currentIndex < count)
            activated(currentIndex);
    }

    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: false
    highlightFollowsCurrentItem: true
    highlightMoveDuration: Motion.fast
    highlightResizeDuration: 0
    currentIndex: 0
    onCountChanged: if (currentIndex >= count || currentIndex < 0) currentIndex = 0

    highlight: Rectangle {
        radius: Theme.radius.normal
        color: Theme.islandRaisedHover
    }
}
