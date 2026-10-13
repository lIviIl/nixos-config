import QtQuick

// A chamfered button with a drawn chevron: direction -1 points left, 1 points right.
Item {
    id: button

    property int direction: 1
    readonly property color ink: Theme.fg

    signal clicked()

    implicitWidth: 38
    implicitHeight: 30

    onInkChanged: arrow.requestPaint()

    Chamfer {
        anchors.fill: parent
        cut: 6
        strokeColor: Theme.alpha(Theme.gold, area.containsMouse ? 1 : 0.6)
        fillTop: area.containsMouse ? Theme.alpha(Theme.fg, 0.08) : "transparent"
    }

    Canvas {
        id: arrow
        anchors.centerIn: parent
        width: 14
        height: 14

        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = button.ink;
            ctx.lineWidth = 2;
            ctx.lineJoin = "miter";
            ctx.beginPath();
            if (button.direction < 0) {
                ctx.moveTo(9.5, 2.5);
                ctx.lineTo(4, 7);
                ctx.lineTo(9.5, 11.5);
            } else {
                ctx.moveTo(4.5, 2.5);
                ctx.lineTo(10, 7);
                ctx.lineTo(4.5, 11.5);
            }
            ctx.stroke();
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
