import QtQuick

// A chamfered button. active fills it; danger edges it in crimson;
// needsConfirm makes the first click arm it ("CONFIRM") and the second one fire.
Item {
    id: button

    property string label: ""
    property bool active: false
    property bool danger: false
    property bool needsConfirm: false
    property bool armed: false

    signal clicked()

    implicitWidth: caption.implicitWidth + 28
    implicitHeight: 32
    opacity: enabled ? 1 : 0.4

    Chamfer {
        anchors.fill: parent
        cut: 6
        strokeColor: button.danger ? Theme.crimson : Theme.alpha(Theme.gold, area.containsMouse ? 1 : 0.6)
        fillTop: button.active ? Theme.primary : (area.containsMouse ? Theme.alpha(Theme.fg, 0.08) : "transparent")
    }

    Text {
        id: caption
        anchors.centerIn: parent
        text: button.armed ? "CONFIRM" : button.label
        color: button.active ? Theme.onPrimary : (button.danger ? Theme.crimson : Theme.fg)
        font.family: Theme.mono
        font.pixelSize: 12
        font.bold: true
        font.letterSpacing: 2
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: button.armed = false
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (button.needsConfirm && !button.armed) {
                button.armed = true;
                disarm.restart();
            } else {
                button.armed = false;
                button.clicked();
            }
        }
    }
}
