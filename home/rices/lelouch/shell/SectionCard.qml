import QtQuick
import QtQuick.Layouts

// A titled, chamfered section. Children go into a column layout that fills the card.
// The subtitle shrinks (with an ellipsis) instead of overlapping the title.
Item {
    id: card

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property real iconLevel: 1.0
    property bool iconMuted: false
    default property alias content: body.data

    Layout.fillWidth: true
    Layout.preferredWidth: 1            // equal widths when several cards share a row
    implicitHeight: 48 + body.implicitHeight + 14

    Chamfer {
        anchors.fill: parent
        cut: 8
        strokeColor: Theme.alpha(Theme.gold, 0.55)
        fillTop: Theme.alpha(Theme.bg, 0.55)
    }

    Glyph {
        visible: card.icon !== ""
        kind: card.icon
        level: card.iconLevel
        muted: card.iconMuted
        tint: Theme.gold
        x: 16
        y: 12
    }

    Text {
        id: titleText
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
        width: Math.max(0, Math.min(implicitWidth, card.width - titleText.x - titleText.implicitWidth - 28))
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
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

    ColumnLayout {
        id: body
        x: 16
        y: 48
        width: parent.width - 32
        height: Math.max(0, parent.height - 62)
        spacing: 8
    }
}
