import QtQuick

// The running timer, in the bar. Left click opens the Focus tab, right click pauses or resumes.
Item {
    id: root

    visible: Focus.active
    width: row.implicitWidth
    height: 28

    function pad(n) {
        return (n < 10 ? "0" : "") + n;
    }

    readonly property string time: {
        const s = Focus.countdown ? Math.ceil(Focus.shown / 1000) : Math.floor(Focus.shown / 1000);
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(s % 60);
    }

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

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: Ui.toggleCenter("focus")
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: Focus.toggle()
    }
}
