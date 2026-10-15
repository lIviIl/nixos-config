import QtQuick

// Title and artist of what is playing. Clipped; while hovered the text scrolls through.
// Left click opens the Media tab, right click plays or pauses.
Item {
    id: root

    readonly property int maxWidth: 280
    readonly property bool hovered: hover.hovered
    readonly property real overflow: Math.max(0, label.implicitWidth - maxWidth)

    visible: Media.present && Media.title !== ""
    width: icon.width + 10 + Math.min(label.implicitWidth, maxWidth)
    height: 28

    Glyph {
        id: icon
        kind: "note"
        tint: Media.playing ? Theme.gold : Theme.alpha(Theme.fg, 0.7)
        anchors.verticalCenter: parent.verticalCenter
    }

    Item {
        x: icon.width + 10
        width: parent.width - x
        height: parent.height
        clip: true

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            width: root.hovered ? implicitWidth : parent.width
            elide: root.hovered ? Text.ElideNone : Text.ElideRight
            text: Media.title + (Media.artist !== "" ? "  —  " + Media.artist : "")
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 13
            font.bold: true
        }

        SequentialAnimation {
            running: root.hovered && root.overflow > 0
            loops: Animation.Infinite

            PauseAnimation { duration: 500 }
            NumberAnimation { target: label; property: "x"; to: -root.overflow; duration: Math.max(600, root.overflow * 28) }
            PauseAnimation { duration: 800 }
            NumberAnimation { target: label; property: "x"; to: 0; duration: 350; easing.type: Easing.OutCubic }

            onRunningChanged: {
                if (!running)
                    label.x = 0;
            }
        }
    }

    // Hover and clicks are separate handlers, so a click never disturbs the hover state
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: Ui.togglePopup("media")
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: Media.toggle()
    }
}
