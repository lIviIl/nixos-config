import QtQuick
import Quickshell
import Quickshell.Wayland

// A full-screen, dimmed overlay with a centered gold-trimmed card.
// Children are placed inside the card.
PanelWindow {
    id: win

    default property alias content: card.data
    property bool open: false
    property int cardWidth: 560
    property int cardHeight: 400

    visible: open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Dimmed backdrop: click anywhere outside the card to close
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: win.open = false
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: win.cardWidth
        height: win.cardHeight
        radius: 16
        color: Theme.alpha(Theme.bg, 0.96)
        border.width: 1
        border.color: Theme.alpha(Theme.gold, 0.9)

        // Swallow clicks so they don't reach the backdrop
        MouseArea {
            anchors.fill: parent
        }
    }
}
