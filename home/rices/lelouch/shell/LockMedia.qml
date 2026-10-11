import QtQuick

// What is playing, with small transport buttons.
Item {
    id: root

    visible: Media.present
    width: row.implicitWidth
    height: 36

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            kind: "note"
            tint: Theme.gold
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 300)
            elide: Text.ElideRight
            text: Media.title + (Media.artist !== "" ? "  —  " + Media.artist : "")
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 13
            font.bold: true
        }

        ActionButton { icon: "prev"; onClicked: Media.previous() }
        ActionButton { icon: Media.playing ? "pause" : "play"; active: Media.playing; onClicked: Media.toggle() }
        ActionButton { icon: "next"; onClicked: Media.next() }
    }
}
