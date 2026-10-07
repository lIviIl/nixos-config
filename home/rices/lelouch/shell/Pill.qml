import QtQuick

// A rounded, gold-trimmed container. Children are laid out in a row.
Rectangle {
    id: pill

    default property alias content: row.data
    property color borderColor: Theme.alpha(Theme.gold, 0.8)
    property int padding: 14
    property int contentSpacing: 12

    signal clicked()
    signal scrolled(int direction)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 34
    radius: 10
    color: Theme.alpha(Theme.bg, 0.88)
    border.width: 1
    border.color: borderColor

    Behavior on color { ColorAnimation { duration: 400 } }
    Behavior on border.color { ColorAnimation { duration: 400 } }

    // Declared before the Row so children (e.g. workspace tiles) get clicks first
    MouseArea {
        anchors.fill: parent
        onClicked: pill.clicked()
        onWheel: wheel => pill.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: pill.contentSpacing
    }
}
