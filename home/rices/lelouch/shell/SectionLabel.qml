import QtQuick
import QtQuick.Layouts

// A small caption with a hairline, to set one group apart from the next inside a card.
RowLayout {
    id: label

    property string text: ""

    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 10

    Text {
        text: label.text
        color: Theme.alpha(Theme.fg, 0.65)
        font.family: Theme.mono
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 3
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.alpha(Theme.gold, 0.35)
    }
}
