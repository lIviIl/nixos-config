import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A panel that drops down from the bar. Its window starts just below the bar and covers the rest of the screen
// invisibly, so a click outside closes it while the bar stays clickable. The page inside is loaded only while
// the panel is on screen, and the card is exactly as tall as the page wants (up to the screen).
PanelWindow {
    id: win

    property string name: ""                    // matches Ui.popup
    property string place: "center"             // left, center or right
    property int cardWidth: 460
    property Component page: null

    readonly property bool open: Ui.popup === name
    readonly property int padTop: 20
    readonly property int padBottom: 22
    readonly property int padSide: 20
    readonly property real maxCard: Math.max(200, height - 4 - 12)
    readonly property real wanted: padTop + padBottom + (loader.item ? loader.item.implicitHeight : 120)

    visible: open || card.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    margins.top: 52

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Typing works once the panel is clicked; it never grabs the keyboard on its own
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: win.name

        function toggle(): void {
            Ui.togglePopup(win.name);
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Ui.popup = ""
    }

    Item {
        id: card
        width: win.cardWidth
        height: Math.min(win.wanted, win.maxCard)
        x: win.place === "left" ? 12 : (win.place === "right" ? win.width - width - 12 : Math.round((win.width - width) / 2))
        y: 4 + (win.open ? 0 : -24)
        opacity: win.open ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        CardFrame {
            anchors.fill: parent
        }

        // Swallow clicks so they don't reach the backdrop
        MouseArea {
            anchors.fill: parent
        }

        Item {
            focus: true
            Keys.onEscapePressed: Ui.popup = ""
        }

        Item {
            x: win.padSide
            y: win.padTop
            width: parent.width - 2 * win.padSide
            height: parent.height - win.padTop - win.padBottom
            clip: true

            Loader {
                id: loader
                width: parent.width
                height: item ? Math.min(item.implicitHeight, win.maxCard - win.padTop - win.padBottom) : 120
                active: win.visible
                sourceComponent: win.page
            }
        }
    }
}
