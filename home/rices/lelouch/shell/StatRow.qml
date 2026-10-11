import QtQuick
import QtQuick.Layouts

// A label on the left, a value on the right.
Item {
    id: row

    property string label: ""
    property string value: ""
    property color valueColor: Theme.fg

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 18

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        color: Theme.alpha(Theme.fg, 0.7)
        font.family: Theme.mono
        font.pixelSize: 12
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: row.value
        color: row.valueColor
        font.family: Theme.mono
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: row.clicked()
    }
}
