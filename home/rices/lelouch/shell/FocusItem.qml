import QtQuick

// The running timer, in the bar. Left click opens the Focus panel, right click pauses or resumes.
Item {
    id: root

    visible: Focus.active
    width: row.implicitWidth
    height: 28

    readonly property string time: Fmt.hms(Focus.countdown ? Math.ceil(Focus.shown / 1000) : Math.floor(Focus.shown / 1000))
    readonly property string tag: Focus.mode === "pomodoro" ? (Focus.phase === "work" ? "FOCUS" : "BREAK") : (Focus.mode === "timer" ? "TIMER" : "WATCH")

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            kind: "timer"
            tint: Focus.running ? Theme.gold : Theme.alpha(Theme.fg, 0.6)
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.tag + " " + root.time
            color: Focus.running ? Theme.fg : Theme.alpha(Theme.fg, 0.65)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Focus.toggle();
            else
                { Ui.anchorTo(root); Ui.togglePopup("focus"); }
        }
    }
}
