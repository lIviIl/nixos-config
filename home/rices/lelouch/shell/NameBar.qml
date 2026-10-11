import QtQuick
import QtQuick.Layouts

// Name and value above, a bar below: the one gauge style used across the drawer.
ColumnLayout {
    id: bar

    property string label: ""
    property string value: ""
    property real fraction: 0
    property color fill: Theme.primary
    property bool lowIsBad: false

    Layout.fillWidth: true
    spacing: 3

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: bar.label
            color: Theme.alpha(Theme.fg, 0.7)
            font.family: Theme.mono
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Text {
            text: bar.value
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
        }
    }

    Meter {
        Layout.fillWidth: true
        Layout.preferredHeight: 8
        value: bar.fraction
        fill: bar.fill
        lowIsBad: bar.lowIsBad
    }
}
