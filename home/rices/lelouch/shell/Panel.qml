import QtQuick
import Quickshell
import Quickshell.Wayland

// A full-screen overlay with a centered chamfered card. Children go inside the card.
// Opens with a quick scale-up and fade (0.05, 0.9, 0.1, 1.05 over 200 ms).
PanelWindow {
    id: win

    default property alias content: card.data
    property bool open: false
    property real cardWidth: 580
    property real cardHeight: 400

    visible: open || card.opacity > 0.01
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

    // Light backdrop: click outside the card to close
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.25)
        opacity: card.opacity

        MouseArea {
            anchors.fill: parent
            onClicked: win.open = false
        }
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: win.cardWidth
        height: win.cardHeight
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.9, 0.1, 1.05, 1, 1]
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.9, 0.1, 1.05, 1, 1]
            }
        }

        // Gold outer edge, with a faint primary-tinted glow at the top
        Chamfer {
            anchors.fill: parent
            cut: 14
            strokeColor: Theme.alpha(Theme.gold, 0.9)
            fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.18), 0.95)
            fillBottom: Theme.alpha(Theme.bg, 0.95)
        }

        // Inner highlight line in the primary color
        Chamfer {
            anchors.fill: parent
            anchors.margins: 5
            cut: 10
            strokeColor: Theme.alpha(Theme.primary, 0.4)
            fillTop: "transparent"
        }

        // Swallow clicks so they don't reach the backdrop
        MouseArea {
            anchors.fill: parent
        }
    }
}
