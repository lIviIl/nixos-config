import QtQuick
import QtQuick.Layouts

Item {
    id: page

    implicitHeight: layout.implicitHeight

    // One layout: its picture, name, a line about it, and a mark when it is the active one
    component LayoutRow: Item {
        id: row

        property var entry: ({})
        property bool active: false

        signal chosen()

        width: parent ? parent.width : 0
        height: 56

        Rectangle {
            anchors.fill: parent
            color: row.active ? Theme.alpha(Theme.primary, 0.2) : "transparent"
        }

        Glyph {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            kind: "tile-" + row.entry.id
            tint: row.active ? Theme.gold : Theme.fg
            scale: 1.4
        }

        Column {
            x: 58
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 58 - 44
            spacing: 3

            Text {
                text: row.entry.label
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                width: parent.width
                text: row.entry.hint
                color: Theme.alpha(Theme.fg, 0.65)
                font.family: Theme.mono
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Chamfer {
            visible: row.active
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            cut: 4
            strokeColor: Theme.gold
            fillTop: Theme.gold
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.chosen()
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        SectionCard {
            icon: "tile-" + Tiling.current
            title: "WINDOW LAYOUT"
            subtitle: Tiling.current.toUpperCase()

            Repeater {
                model: Tiling.layouts

                LayoutRow {
                    required property var modelData

                    Layout.fillWidth: true
                    entry: modelData
                    active: Tiling.current === modelData.id
                    onChosen: Tiling.set(modelData.id)
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Super+Y cycles through them. Right-click the bar icon does the same."
                color: Theme.alpha(Theme.fg, 0.55)
                font.family: Theme.mono
                font.pixelSize: 10
                wrapMode: Text.Wrap
            }
        }
    }
}
