import QtQuick

// The time. Click it for the calendar.
Item {
    id: root

    property date now: new Date()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Row {
        id: row
        spacing: 9

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            kind: "clock"
            tint: Theme.gold
            hours: root.now.getHours()
            minutes: root.now.getMinutes()
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: Theme.fg
            font.family: Theme.serif
            font.pixelSize: 18
            font.letterSpacing: 3
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.togglePopup("calendar")
    }
}
