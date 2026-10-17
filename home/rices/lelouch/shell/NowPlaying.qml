import QtQuick

// Title and artist of what is playing, clipped to a fixed width. If the text doesn't fit, it scrolls through
// by itself every few seconds while music plays. Left click opens the media panel, right click plays or pauses.
Item {
    id: root

    readonly property int maxWidth: 280
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
            text: Media.title + (Media.artist !== "" ? "  —  " + Media.artist : "")
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 13
            font.bold: true
        }

        SequentialAnimation {
            running: root.overflow > 0 && Media.playing
            loops: Animation.Infinite

            PauseAnimation { duration: 2500 }
            NumberAnimation { target: label; property: "x"; to: -root.overflow; duration: Math.max(800, root.overflow * 30) }
            PauseAnimation { duration: 1500 }
            NumberAnimation { target: label; property: "x"; to: 0; duration: 400; easing.type: Easing.OutCubic }

            onRunningChanged: {
                if (!running)
                    label.x = 0;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Media.toggle();
            else
                Ui.togglePopup("media");
        }
    }
}
