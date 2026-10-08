import QtQuick

Row {
    id: root
    spacing: 9

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Icon {
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
