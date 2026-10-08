import QtQuick

// An icon followed by text, with optional click and scroll handling.
Item {
    id: item

    property string kind: "clock"
    property string text: ""
    property color tint: Theme.fg
    property real level: 1.0
    property bool muted: false
    property bool charging: false

    signal clicked()
    signal scrolled(int direction)

    implicitWidth: content.implicitWidth
    implicitHeight: 24

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            kind: item.kind
            tint: item.tint
            level: item.level
            muted: item.muted
            charging: item.charging
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: item.text
            color: item.tint
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: item.clicked()
        onWheel: wheel => item.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
