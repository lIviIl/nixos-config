import QtQuick

// One notification card. The list that holds it (Notifications.qml) animates it in and out.
Item {
    id: toast

    required property int key
    required property string summary
    required property string body
    required property bool critical
    required property bool low

    signal dismissRequested()

    readonly property color accent: critical ? Theme.crimson : (low ? Theme.outline : Theme.gold)

    width: ListView.view ? ListView.view.width : 380
    height: Math.max(66, texts.implicitHeight + 28)

    Chamfer {
        anchors.fill: parent
        cut: 8
        strokeColor: Theme.alpha(toast.accent, 0.9)
        fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.12), 0.95)
        fillBottom: Theme.alpha(Theme.bg, 0.95)
    }

    // Left accent: crimson for critical, gold for normal
    Rectangle {
        x: 12
        y: 14
        width: 3
        height: parent.height - 28
        color: toast.accent
    }

    Column {
        id: texts
        x: 28
        y: 14
        width: parent.width - 28 - 16
        spacing: 4

        Text {
            width: parent.width
            text: toast.summary
            color: Theme.fg
            font.family: Theme.mono
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: toast.body
            color: Theme.alpha(Theme.fg, 0.8)
            font.family: Theme.mono
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }

    // Click to dismiss; hovering pauses the timeout
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: toast.dismissRequested()
    }

    Timer {
        interval: toast.critical ? 12000 : 6000
        running: !hover.containsMouse
        onTriggered: toast.dismissRequested()
    }
}
