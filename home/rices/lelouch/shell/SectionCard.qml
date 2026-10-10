import QtQuick

// A titled, chamfered section with an optional icon. Children are stacked inside it.
Item {
    id: card

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    default property alias content: body.data

    implicitHeight: 48 + body.implicitHeight + 16

    Chamfer {
        anchors.fill: parent
        cut: 8
        strokeColor: Theme.alpha(Theme.gold, 0.55)
        fillTop: Theme.alpha(Theme.bg, 0.55)
    }

    Glyph {
        visible: card.icon !== ""
        kind: card.icon
        tint: Theme.gold
        x: 16
        y: 12
    }

    Text {
        x: card.icon !== "" ? 42 : 16
        y: 12
        text: card.title
        color: Theme.gold
        font.family: Theme.serif
        font.pixelSize: 15
        font.letterSpacing: 3
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: 13
        text: card.subtitle
        color: Theme.fg
        font.family: Theme.mono
        font.pixelSize: 13
        font.bold: true
    }

    Rectangle {
        x: 16
        y: 38
        width: parent.width - 32
        height: 1
        color: Theme.alpha(Theme.gold, 0.4)
    }

    Column {
        id: body
        x: 16
        y: 48
        width: parent.width - 32
        spacing: 8
    }
}
