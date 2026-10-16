import QtQuick
import Quickshell
import Quickshell.Wayland

// An overlay with a centered card (the launcher, the wallpaper picker, the scratchpad). Children go inside the card.
// A modal panel dims the screen and closes when you click outside it. A non-modal one (modal: false) takes input
// only inside its card, so the desktop stays usable around it. Opens with a quick scale-up and fade.
PanelWindow {
    id: win

    default property alias content: card.data
    property bool open: false
    property bool modal: true
    property real cardWidth: 580
    property real cardHeight: 400

    visible: open || card.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: win.modal ? null : cardMask

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? (modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

    // The card's final place, used as the input region of a non-modal panel
    Item {
        id: hitbox
        x: Math.round((win.width - win.cardWidth) / 2)
        y: Math.round((win.height - win.cardHeight) / 2)
        width: win.cardWidth
        height: win.cardHeight
    }

    Region {
        id: cardMask
        item: hitbox
    }

    // Light backdrop: click anywhere outside the card to close
    Rectangle {
        visible: win.modal
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

        CardFrame {
            anchors.fill: parent
        }

        // Swallow clicks so they don't reach the backdrop
        MouseArea {
            anchors.fill: parent
        }
    }
}
