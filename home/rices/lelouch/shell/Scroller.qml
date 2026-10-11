import QtQuick
import QtQuick.Layouts

// A vertical list that grows with its contents up to maxHeight, then scrolls
// (mouse wheel or drag). A thin gold bar shows when there is more.
Item {
    id: scroller

    property real maxHeight: 240
    default property alias content: inner.data
    readonly property bool overflowing: flick.contentHeight > flick.height + 1

    Layout.fillWidth: true
    implicitHeight: Math.min(inner.implicitHeight, maxHeight)
    Layout.preferredHeight: implicitHeight

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: inner.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: inner
            width: flick.width - (scroller.overflowing ? 10 : 0)
            spacing: 6
        }
    }

    Rectangle {
        visible: scroller.overflowing
        x: scroller.width - 3
        y: flick.visibleArea.yPosition * scroller.height
        width: 3
        height: Math.max(20, flick.visibleArea.heightRatio * scroller.height)
        color: Theme.alpha(Theme.gold, 0.8)
    }
}
