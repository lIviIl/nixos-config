import QtQuick

Pill {
    id: root

    borderColor: Theme.gold
    padding: 20

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        text: Qt.formatDateTime(root.now, "HH:mm")
        color: Theme.fg
        font.family: Theme.serif
        font.pixelSize: 17
        font.letterSpacing: 3
    }
}
