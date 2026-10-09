import QtQuick

// The bar button that opens the command center: four squares.
Item {
    id: button

    width: 28
    height: 28

    Canvas {
        id: glyph
        anchors.centerIn: parent
        width: 16
        height: 16

        property color tint: Ui.centerOpen ? Theme.gold : Theme.fg

        onTintChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = tint;
            ctx.fillRect(1, 1, 6, 6);
            ctx.fillRect(9, 1, 6, 6);
            ctx.fillRect(1, 9, 6, 6);
            ctx.fillRect(9, 9, 6, 6);
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.centerOpen = !Ui.centerOpen
    }
}
