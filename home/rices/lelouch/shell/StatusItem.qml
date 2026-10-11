import QtQuick

// An icon followed by text. Left click, right click and scrolling are reported.
Item {
    id: item

    property string kind: "clock"
    property string text: ""
    property color tint: Theme.fg
    property real level: 1.0
    property bool muted: false
    property bool charging: false

    signal clicked()
    signal rightClicked()
    signal scrolled(int direction)

    implicitWidth: content.implicitWidth
    implicitHeight: 24

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Glyph {
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                item.rightClicked();
            else
                item.clicked();
        }

        onWheel: wheel => item.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
