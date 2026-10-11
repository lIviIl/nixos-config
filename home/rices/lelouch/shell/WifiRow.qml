import QtQuick

// One Wi-Fi network: signal, name, state. The page decides what a click does;
// a new protected network shows a password field.
Column {
    id: row

    property var network: ({})
    property bool known: false
    property bool asking: false

    signal activated()
    signal passwordEntered(string password)
    signal cancelled()

    spacing: 4

    Item {
        width: parent.width
        height: 36

        Rectangle {
            anchors.fill: parent
            color: hover.containsMouse ? Theme.alpha(Theme.fg, 0.07) : (row.network.inUse ? Theme.alpha(Theme.primary, 0.2) : "transparent")
        }

        Glyph {
            kind: "wifi"
            level: row.network.signal
            tint: row.network.inUse ? Theme.gold : Theme.fg
            x: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            x: 36
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 36 - 130
            elide: Text.ElideRight
            text: row.network.ssid
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 13
            font.bold: true
        }

        Glyph {
            visible: row.network.secured
            kind: "lock"
            tint: Theme.alpha(Theme.fg, 0.7)
            anchors.right: tag.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: tag
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 86
            horizontalAlignment: Text.AlignRight
            text: row.network.inUse ? "CONNECTED" : (row.known ? "SAVED" : (row.network.secured ? "" : "OPEN"))
            color: Theme.gold
            font.family: Theme.mono
            font.pixelSize: 11
            font.bold: true
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.activated()
        }
    }

    Item {
        visible: row.asking
        width: parent.width
        height: 34

        Chamfer {
            anchors.fill: parent
            cut: 5
            strokeColor: Theme.alpha(Theme.gold, 0.8)
            fillTop: "transparent"
        }

        TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Theme.fg
            selectionColor: Theme.primary
            selectedTextColor: Theme.onPrimary
            font.family: Theme.mono
            font.pixelSize: 13
            clip: true

            onVisibleChanged: {
                if (visible) {
                    text = "";
                    forceActiveFocus();
                }
            }

            onAccepted: row.passwordEntered(text)
            Keys.onEscapePressed: row.cancelled()
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: password.text === ""
            text: "Password, then Enter"
            color: Theme.alpha(Theme.fg, 0.5)
            font.family: Theme.mono
            font.pixelSize: 13
        }
    }
}
