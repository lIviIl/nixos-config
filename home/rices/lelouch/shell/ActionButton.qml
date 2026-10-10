import QtQuick

// A chamfered button, optionally with an icon (beside the label, or above it when vertical).
// active fills it; danger edges it in crimson;
// needsConfirm makes the first click arm it ("CONFIRM") and the second one fire.
Item {
    id: button

    property string label: ""
    property string icon: ""
    property bool vertical: false
    property bool active: false
    property bool danger: false
    property bool needsConfirm: false
    property bool armed: false

    readonly property color ink: active ? Theme.onPrimary : (danger ? Theme.crimson : Theme.fg)

    signal clicked()

    implicitWidth: Math.ceil(content.implicitWidth) + 28
    implicitHeight: vertical ? 60 : 34
    opacity: enabled ? 1 : 0.4

    Chamfer {
        anchors.fill: parent
        cut: 6
        strokeColor: button.danger ? Theme.crimson : Theme.alpha(Theme.gold, area.containsMouse ? 1 : 0.6)
        fillTop: button.active ? Theme.primary : (area.containsMouse ? Theme.alpha(Theme.fg, 0.08) : "transparent")
    }

    Grid {
        id: content
        anchors.centerIn: parent
        columns: button.vertical ? 1 : 2
        spacing: button.vertical ? 6 : 9
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Glyph {
            visible: button.icon !== ""
            kind: button.icon
            tint: button.ink
        }

        Text {
            text: button.armed ? "CONFIRM" : button.label
            color: button.ink
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 2
        }
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
