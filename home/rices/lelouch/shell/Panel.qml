import QtQuick
import Quickshell
import Quickshell.Wayland

// An overlay with a centered card (the launcher, the wallpaper picker, the scratchpad). Children go inside the card.
// A modal panel covers the screen, dims it and closes when you click outside the card; it is mapped only while shown.
// A non-modal panel is a window exactly the size of its card that stays mapped for good, shrinking to one transparent
// pixel while closed: unmapping layer surfaces made clicks on the bar unreliable.
PanelWindow {
    id: win

    default property alias content: card.data
    property bool open: false
    property bool modal: true
    property real cardWidth: 580
    property real cardHeight: 400

    readonly property bool shown: open || card.opacity > 0.01

    visible: modal ? shown : true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: (modal || shown) ? cardWidth : 1
    implicitHeight: (modal || shown) ? cardHeight : 1

    // Only a modal panel is stretched over the whole screen
    anchors {
        top: win.modal
        bottom: win.modal
        left: win.modal
        right: win.modal
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? (modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

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
