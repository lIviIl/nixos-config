import QtQuick

// An icon, a label with a short hint, and a switch.
Item {
    id: row

    property string icon: ""
    property string label: ""
    property string hint: ""
    property bool checked: false

    signal toggled()

    width: parent ? parent.width : 0
    height: 46
    opacity: enabled ? 1 : 0.4

    Glyph {
        id: glyph
        visible: row.icon !== ""
        kind: row.icon
        tint: row.checked ? Theme.gold : Theme.alpha(Theme.fg, 0.8)
        x: 2
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: toggle.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: row.label
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: row.hint !== ""
            text: row.hint
            color: Theme.alpha(Theme.fg, 0.65)
            font.family: Theme.mono
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Item {
        id: toggle
        width: 46
        height: 22
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Chamfer {
            anchors.fill: parent
            cut: 6
            strokeColor: row.checked ? Theme.gold : Theme.alpha(Theme.gold, 0.5)
            fillTop: row.checked ? Theme.alpha(Theme.primary, 0.4) : Theme.alpha(Theme.fg, 0.08)
        }

        // Diamond knob
        Rectangle {
            width: 10
            height: 10
            rotation: 45
            color: row.checked ? Theme.gold : Theme.alpha(Theme.fg, 0.6)
            y: (toggle.height - height) / 2
            x: (row.checked ? toggle.width - 13 : 13) - width / 2

            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggled()
    }
}
